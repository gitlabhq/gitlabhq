# frozen_string_literal: true

require_relative '../config/bundler_setup'

require 'optparse'
require 'logger'
require 'time'

# In environments where code is preloaded and cached such as `spring`,
# we may run into "already initialized" warnings, hence the check.
require_relative '../lib/gitlab' unless Object.const_defined?('Gitlab')
require_relative '../lib/gitlab/utils'
require_relative '../lib/gitlab/sidekiq_config/cli_methods'
require_relative '../lib/gitlab/sidekiq_config/worker_matcher'
require_relative '../lib/gitlab/sidekiq_logging/json_formatter'
require_relative '../lib/gitlab/process_management'
require_relative '../metrics_server/metrics_server'
require_relative 'sidekiq_cluster'

module Gitlab
  module SidekiqCluster
    class CLI
      THREAD_NAME = 'supervisor'

      # The signals that should terminate both the master and workers.
      TERMINATE_SIGNALS = %i(INT TERM).freeze

      # The signals that should simply be forwarded to the workers.
      FORWARD_SIGNALS = %i(TTIN USR1 USR2 HUP).freeze

      CommandError = Class.new(StandardError)

      def initialize(log_output = $stderr)
        # As recommended by https://github.com/mperham/sidekiq/wiki/Advanced-Options#concurrency
        @max_concurrency = 50
        @min_concurrency = 0
        @environment = ENV['RAILS_ENV'] || 'development'
        @metrics_dir = ENV["prometheus_multiproc_dir"] || File.absolute_path("tmp/prometheus_multiproc_dir/sidekiq")
        @pid = nil
        @interval = 5
        @alive = true
        @processes = []
        @logger = Logger.new(log_output)
        @logger.formatter = ::Gitlab::SidekiqLogging::JSONFormatter.new
        @rails_path = Dir.pwd
        @dryrun = false
        @list_queues = false
      end

      def run(argv = ARGV)
        Thread.current.name = THREAD_NAME

        if argv.empty?
          raise CommandError,
            'You must specify at least one queue to start a worker for'
        end

        option_parser.parse!(argv)

        if @dryrun && @list_queues
          raise CommandError,
            'The --dryrun and --list-queues options are mutually exclusive'
        end

        worker_metadatas = SidekiqConfig::CliMethods.worker_metadatas(@rails_path)
        worker_queues = SidekiqConfig::CliMethods.worker_queues(@rails_path)

        queue_groups = argv.map do |queues_or_query_string|
          if queues_or_query_string =~ /[\r\n]/
            raise CommandError,
              'The queue arguments cannot contain newlines'
          end

          next worker_queues if queues_or_query_string == SidekiqConfig::WorkerMatcher::WILDCARD_MATCH

          # When using the queue query syntax, we treat each queue group
          # as a worker attribute query, and resolve the queues for the
          # queue group using this query.

          if @queue_selector
            SidekiqConfig::CliMethods.query_queues(queues_or_query_string, worker_metadatas)
          else
            SidekiqConfig::CliMethods.expand_queues(queues_or_query_string.split(','), worker_queues)
          end
        end

        if @negate_queues
          queue_groups.map! { |queues| worker_queues - queues }
        end

        if queue_groups.all?(&:empty?)
          raise CommandError,
            'No queues found, you must select at least one queue'
        end

        if @list_queues
          puts queue_groups.map(&:sort) # rubocop:disable Rails/Output

          return
        end

        unless @dryrun
          @logger.info("Starting cluster with #{queue_groups.length} processes")
        end

        start_metrics_server(wipe_metrics_dir: true)

        @processes = SidekiqCluster.start(
          queue_groups,
          env: @environment,
          directory: @rails_path,
          max_concurrency: @max_concurrency,
          min_concurrency: @min_concurrency,
          dryrun: @dryrun,
          timeout: soft_timeout_seconds
        )

        return if @dryrun

        write_pid
        trap_signals
        start_loop
      end

      def write_pid
        ProcessManagement.write_pid(@pid) if @pid
      end

      def soft_timeout_seconds
        @soft_timeout_seconds || DEFAULT_SOFT_TIMEOUT_SECONDS
      end

      # The amount of time it'll wait for killing the alive Sidekiq processes.
      def hard_timeout_seconds
        soft_timeout_seconds + DEFAULT_HARD_TIMEOUT_SECONDS
      end

      def monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_second)
      end

      def continue_waiting?(deadline)
        ProcessManagement.any_alive?(@processes) && monotonic_time < deadline
      end

      def hard_stop_stuck_pids
        ProcessManagement.signal_processes(ProcessManagement.pids_alive(@processes), "-KILL")
      end

      def wait_for_termination
        deadline = monotonic_time + hard_timeout_seconds
        sleep(CHECK_TERMINATE_INTERVAL_SECONDS) while continue_waiting?(deadline)

        hard_stop_stuck_pids
      end

      def trap_signals
        ProcessManagement.trap_signals(TERMINATE_SIGNALS) do |signal|
          @alive = false
          ProcessManagement.signal_processes(@processes, signal)
          wait_for_termination
        end

        ProcessManagement.trap_signals(FORWARD_SIGNALS) do |signal|
          ProcessManagement.signal_processes(@processes, signal)
        end
      end

      def start_loop
        while @alive
          sleep(@interval)

          if metrics_server_enabled? && ProcessManagement.process_died?(@metrics_server_pid)
            @logger.warn('Metrics server went away')
            start_metrics_server(wipe_metrics_dir: false)
          end

          unless ProcessManagement.all_alive?(@processes)
            # If a child process died we'll just terminate the whole cluster. It's up to
            # runit and such to then restart the cluster.
            @logger.info('A worker terminated, shutting down the cluster')

            stop_metrics_server
            ProcessManagement.signal_processes(@processes, :TERM)
            break
          end
        end
      end

      def start_metrics_server(wipe_metrics_dir: false)
        return unless metrics_server_enabled?

        @logger.info("Starting metrics server on port #{sidekiq_exporter_port}")
        @metrics_server_pid = MetricsServer.fork(
          'sidekiq',
          metrics_dir: @metrics_dir,
          wipe_metrics_dir: wipe_metrics_dir,
          reset_signals: TERMINATE_SIGNALS + FORWARD_SIGNALS
        )
      end

      def sidekiq_exporter_enabled?
        ::Settings.dig('monitoring', 'sidekiq_exporter', 'enabled')
      end

      def exporter_has_a_unique_port?
        # In https://gitlab.com/gitlab-org/gitlab/-/issues/345802 we added settings for sidekiq_health_checks.
        # These settings default to the same values as sidekiq_exporter for backwards compatibility.
        # If a different port for sidekiq_health_checks has been set up, we know that the
        # user wants to serve health checks and metrics from different servers.
        return false if sidekiq_health_check_port.nil? || sidekiq_exporter_port.nil?

        sidekiq_exporter_port != sidekiq_health_check_port
      end

      def sidekiq_exporter_port
        ::Settings.dig('monitoring', 'sidekiq_exporter', 'port')
      end

      def sidekiq_health_check_port
        ::Settings.dig('monitoring', 'sidekiq_health_checks', 'port')
      end

      def metrics_server_enabled?
        !@dryrun && sidekiq_exporter_enabled? && exporter_has_a_unique_port?
      end

      def stop_metrics_server
        return unless @metrics_server_pid

        @logger.info("Stopping metrics server (PID #{@metrics_server_pid})")
        ProcessManagement.signal(@metrics_server_pid, :TERM)
      end

      def option_parser
        OptionParser.new do |opt|
          opt.banner = "#{File.basename(__FILE__)} [QUEUE,QUEUE] [QUEUE] ... [OPTIONS]"

          opt.separator "\nOptions:\n"

          opt.on('-h', '--help', 'Shows this help message') do
            abort opt.to_s
          end

          opt.on('-m', '--max-concurrency INT', 'Maximum threads to use with Sidekiq (default: 50, 0 to disable)') do |int|
            @max_concurrency = int.to_i
          end

          opt.on('--min-concurrency INT', 'Minimum threads to use with Sidekiq (default: 0)') do |int|
            @min_concurrency = int.to_i
          end

          opt.on('-e', '--environment ENV', 'The application environment') do |env|
            @environment = env
          end

          opt.on('-P', '--pidfile PATH', 'Path to the PID file') do |pid|
            @pid = pid
          end

          opt.on('-r', '--require PATH', 'Location of the Rails application') do |path|
            @rails_path = path
          end

          opt.on('--queue-selector', 'Run workers based on the provided selector') do |queue_selector|
            @queue_selector = queue_selector
          end

          opt.on('-n', '--negate', 'Run workers for all queues in sidekiq_queues.yml except the given ones') do
            @negate_queues = true
          end

          opt.on('-i', '--interval INT', 'The number of seconds to wait between worker checks') do |int|
            @interval = int.to_i
          end

          opt.on('-t', '--timeout INT', 'Graceful timeout for all running processes') do |timeout|
            @soft_timeout_seconds = timeout.to_i
          end

          opt.on('-d', '--dryrun', 'Print commands that would be run without this flag, and quit') do |int|
            @dryrun = true
          end

          opt.on('--list-queues', 'List matching queues, and quit') do |int|
            @list_queues = true
          end
        end
      end
    end
  end
end
