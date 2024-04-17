# frozen_string_literal: true

require_relative '../lib/gitlab/process_management'
require_relative '../lib/gitlab/process_supervisor'

module Gitlab
  module SidekiqCluster
    # How long to wait when asking for a clean termination.
    # It maps the Sidekiq default timeout:
    # https://github.com/mperham/sidekiq/wiki/Signals#term
    #
    # This value is passed to Sidekiq's `-t` if none
    # is given through arguments.
    DEFAULT_SOFT_TIMEOUT_SECONDS = 25

    # Additional time granted after surpassing the soft timeout
    # before we kill the process.
    TIMEOUT_GRACE_PERIOD_SECONDS = 5

    # The singleton instance used to supervise cluster processes.
    SidekiqProcessSupervisor = Class.new(Gitlab::ProcessSupervisor)

    # Starts Sidekiq workers for the pairs of processes.
    #
    # Example:
    #
    #     start([ ['foo'], ['bar', 'baz'] ], :production)
    #
    # This would start two Sidekiq processes: one processing "foo", and one
    # processing "bar" and "baz". Each one is placed in its own process group.
    #
    # queues - An Array containing Arrays. Each sub Array should specify the
    #          queues to use for a single process.
    #
    # directory - The directory of the Rails application.
    #
    # Returns an Array containing the waiter threads (from Process.detach) of
    # the started processes.
    def self.start(queues, env: :development, directory: Dir.pwd, max_concurrency: 20, min_concurrency: 0, concurrency: 0, timeout: DEFAULT_SOFT_TIMEOUT_SECONDS, dryrun: false)
      queues.map.with_index do |pair, index|
        start_sidekiq(pair, env: env,
                            directory: directory,
                            max_concurrency: max_concurrency,
                            min_concurrency: min_concurrency,
                            concurrency: concurrency,
                            worker_id: index,
                            timeout: timeout,
                            dryrun: dryrun)
      end
    end

    # Starts a Sidekiq process that processes _only_ the given queues.
    #
    # Returns the PID of the started process.
    # rubocop: disable Metrics/ParameterLists -- max_concurrency and min_concurrency will be removed in 17.0
    def self.start_sidekiq(queues, env:, directory:, max_concurrency:, min_concurrency:, concurrency:, worker_id:, timeout:, dryrun:)
      # rubocop: enable Metrics/ParameterLists
      counts = count_by_queue(queues)

      cmd = %w[bundle exec sidekiq]
      cmd << "-c#{self.concurrency(queues, min_concurrency, max_concurrency, concurrency)}"
      cmd << "-e#{env}"
      cmd << "-t#{timeout}"
      cmd << "-gqueues:#{proc_details(counts)}"
      cmd << "-r#{directory}"

      counts.each do |queue, count|
        cmd << "-q#{queue},#{count}"
      end

      if dryrun
        puts Shellwords.join(cmd) # rubocop:disable Rails/Output
        return
      end

      # We need to remove Bundler specific env vars, since otherwise the
      # child process will think we are passing an alternative Gemfile
      # and will clear and reset LOAD_PATH.
      pid = Bundler.with_original_env do
        Process.spawn(
          { 'ENABLE_SIDEKIQ_CLUSTER' => '1',
            'SIDEKIQ_WORKER_ID' => worker_id.to_s },
          *cmd,
          pgroup: true,
          err: $stderr,
          out: $stdout
        )
      end

      Process.detach(pid)
    end

    def self.count_by_queue(queues)
      queues.tally
    end

    def self.proc_details(counts)
      counts.map do |queue, count|
        if count == 1
          queue
        else
          "#{queue} (#{count})"
        end
      end.join(',')
    end

    def self.concurrency(queues, min_concurrency, max_concurrency, concurrency)
      return concurrency if concurrency > 0

      concurrency_from_queues = queues.length + 1
      max = max_concurrency > 0 ? max_concurrency : concurrency_from_queues
      min = [min_concurrency, max].min

      concurrency_from_queues.clamp(min, max)
    end
  end
end
