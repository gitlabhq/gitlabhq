# frozen_string_literal: true

require_relative '../config/bundler_setup'

require 'optparse'
require 'logger'
require 'time'
require 'gitlab/utils/all'

# In environments where code is preloaded and cached such as `spring`,
# we may run into "already initialized" warnings, hence the check.
require_relative '../lib/gitlab'
require_relative '../lib/gitlab/sidekiq_config/cli_methods'
require_relative '../lib/gitlab/sidekiq_config/worker_matcher'
require_relative '../lib/gitlab/sidekiq_logging/json_formatter'
require_relative '../metrics_server/dependencies'
require_relative '../metrics_server/metrics_server'
require_relative 'sidekiq_cluster'

module Gitlab
  module SidekiqCluster
    class CLI
      THREAD_NAME = 'sidekiq-cluster'

      # The signals that should terminate both the master and workers.
      TERMINATE_SIGNALS = %i[INT TERM].freeze

      # The signals that should simply be forwarded to the workers.
      FORWARD_SIGNALS = %i[TTIN USR1 USR2 HUP].freeze

      # The default queues that each Sidekiq process always listens to if routing rules are not customized:
      # - `default` queue comes from config initializer's Settings.build_sidekiq_routing_rules
      # - `mailers` queue comes from Gitlab::Application.config.action_mailer.deliver_later_queue_name
      DEFAULT_QUEUES = %w[default mailers].freeze

      CommandError = Class.new(StandardError)

      def initialize(log_output = $stderr)
        # https://github.com/mperham/sidekiq/wiki/Advanced-Options#concurrency
        # https://ruby.social/@getajobmike/109326475545816363
        @concurrency = 20
        @environment = ENV['RAILS_ENV'] || 'development'
        @metrics_dir = ENV["prometheus_multiproc_dir"] || File.absolute_path("tmp/prometheus_multiproc_dir/sidekiq")
        @pid = nil
        @interval = 5
        @soft_timeout_seconds = DEFAULT_SOFT_TIMEOUT_SECONDS
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

        # Routing rules are defaulted to [['*', 'default']] if not specified.
        # This means all jobs go to 'default' queue and mailer jobs go to 'mailers' queue.
        # See config/initializers/1_settings.rb and Settings.build_sidekiq_routing_rules.
        available_queues = queues_from_routing_rules.empty? ? DEFAULT_QUEUES : [*queues_from_routing_rules, 'mailers'].freeze

        queue_groups = argv.map do |queues|
          if /[\r\n]/.match?(queues)
            raise CommandError,
              'The queue arguments cannot contain newlines'
          end

          # Empty routing rules means Sidekiq only needs to listen to DEFAULT_QUEUES.
          next available_queues if queues == SidekiqConfig::WorkerMatcher::WILDCARD_MATCH || routing_rules.empty?

          queues.split(',')
        end

        if queue_groups.all?(&:empty?)
          raise CommandError,
            'No queues found, you must select at least one queue'
        end

        if @list_queues
          puts queue_groups.map(&:sort)

          return
        end

        unless @dryrun
          @logger.info("Starting cluster with #{queue_groups.length} processes")

          # Make sure we reset the metrics directory prior to:
          # - starting a metrics server process
          # - starting new workers
          ::Prometheus::CleanupMultiprocDirService.new(@metrics_dir).execute
        end

        start_and_supervise_workers(queue_groups)
      end

      def start_and_supervise_workers(queue_groups)
        wait_threads = SidekiqCluster.start(
          queue_groups,
          env: @environment,
          directory: @rails_path,
          concurrency: @concurrency,
          dryrun: @dryrun,
          timeout: @soft_timeout_seconds
        )

        return if @dryrun

        ProcessManagement.write_pid(@pid) if @pid

        supervisor = SidekiqProcessSupervisor.instance(
          health_check_interval_seconds: @interval,
          terminate_timeout_seconds: @soft_timeout_seconds + TIMEOUT_GRACE_PERIOD_SECONDS,
          term_signals: TERMINATE_SIGNALS,
          forwarded_signals: FORWARD_SIGNALS,
          synchronous: true
        )

        metrics_server_pid = start_metrics_server
        worker_pids = wait_threads.map(&:pid)
        supervisor.supervise(worker_pids + Array(metrics_server_pid)) do |dead_pids|
          # If we're not in the process of shutting down the cluster,
          # and the metrics server died, restart it.
          if dead_pids == Array(metrics_server_pid)
            @logger.info('Sidekiq metrics server terminated, restarting...')
            metrics_server_pid = restart_metrics_server
          else
            # If a worker process died we'll just terminate the whole cluster.
            # We let an external system (runit, kubernetes) handle the restart.
            @logger.info('A worker terminated, shutting down the cluster')
            supervisor.shutdown
            []
          end
        end

        exit_statuses = wait_threads.map do |thread|
          thread.join
          thread.value
        end

        exit 1 unless exit_statuses.compact.all?(&:success?)
      end

      def start_metrics_server
        return unless metrics_server_enabled?

        restart_metrics_server
      end

      def restart_metrics_server
        @logger.info("Starting metrics server on port #{sidekiq_exporter_port}")
        MetricsServer.start_for_sidekiq(
          metrics_dir: @metrics_dir,
          reset_signals: TERMINATE_SIGNALS + FORWARD_SIGNALS
        )
      end

      def sidekiq_exporter_enabled?
        ::Settings.dig('monitoring', 'sidekiq_exporter', 'enabled')
      end

      def sidekiq_exporter_port
        ::Settings.dig('monitoring', 'sidekiq_exporter', 'port')
      end

      def metrics_server_enabled?
        !@dryrun && sidekiq_exporter_enabled?
      end

      def routing_rules
        ::Gitlab.config.sidekiq.routing_rules || []
      rescue StandardError
        []
      end

      def queues_from_routing_rules
        routing_rules.flat_map(&:second).uniq
      end

      def option_parser
        OptionParser.new do |opt|
          opt.banner = "#{File.basename(__FILE__)} [QUEUE,QUEUE] [QUEUE] ... [OPTIONS]"

          opt.separator "\nOptions:\n"

          opt.on('-h', '--help', 'Shows this help message') do
            abort opt.to_s
          end

          opt.on('-c', '--concurrency INT', 'Number of threads to use with Sidekiq (default: 0)') do |int|
            @concurrency = int.to_i
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
