# frozen_string_literal: true

require 'shellwords'

module Gitlab
  module SidekiqCluster
    # The signals that should terminate both the master and workers.
    TERMINATE_SIGNALS = %i(INT TERM).freeze

    # The signals that should simply be forwarded to the workers.
    FORWARD_SIGNALS = %i(TTIN USR1 USR2 HUP).freeze

    # Traps the given signals and yields the block whenever these signals are
    # received.
    #
    # The block is passed the name of the signal.
    #
    # Example:
    #
    #     trap_signals(%i(HUP TERM)) do |signal|
    #       ...
    #     end
    def self.trap_signals(signals)
      signals.each do |signal|
        trap(signal) do
          yield signal
        end
      end
    end

    def self.trap_terminate(&block)
      trap_signals(TERMINATE_SIGNALS, &block)
    end

    def self.trap_forward(&block)
      trap_signals(FORWARD_SIGNALS, &block)
    end

    def self.signal(pid, signal)
      Process.kill(signal, pid)
      true
    rescue Errno::ESRCH
      false
    end

    def self.signal_processes(pids, signal)
      pids.each { |pid| signal(pid, signal) }
    end

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
    # Returns an Array containing the PIDs of the started processes.
    def self.start(queues, env: :development, directory: Dir.pwd, max_concurrency: 50, min_concurrency: 0, timeout: CLI::DEFAULT_SOFT_TIMEOUT_SECONDS, dryrun: false)
      queues.map.with_index do |pair, index|
        start_sidekiq(pair, env: env,
                            directory: directory,
                            max_concurrency: max_concurrency,
                            min_concurrency: min_concurrency,
                            worker_id: index,
                            timeout: timeout,
                            dryrun: dryrun)
      end
    end

    # Starts a Sidekiq process that processes _only_ the given queues.
    #
    # Returns the PID of the started process.
    def self.start_sidekiq(queues, env:, directory:, max_concurrency:, min_concurrency:, worker_id:, timeout:, dryrun:)
      counts = count_by_queue(queues)

      cmd = %w[bundle exec sidekiq]
      cmd << "-c#{self.concurrency(queues, min_concurrency, max_concurrency)}"
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

      pid = Process.spawn(
        { 'ENABLE_SIDEKIQ_CLUSTER' => '1',
          'SIDEKIQ_WORKER_ID' => worker_id.to_s },
        *cmd,
        pgroup: true,
        err: $stderr,
        out: $stdout
      )

      wait_async(pid)

      pid
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

    def self.concurrency(queues, min_concurrency, max_concurrency)
      concurrency_from_queues = queues.length + 1
      max = max_concurrency > 0 ? max_concurrency : concurrency_from_queues
      min = [min_concurrency, max].min

      concurrency_from_queues.clamp(min, max)
    end

    # Waits for the given process to complete using a separate thread.
    def self.wait_async(pid)
      Thread.new do
        Process.wait(pid) rescue Errno::ECHILD
      end
    end

    # Returns true if all the processes are alive.
    def self.all_alive?(pids)
      pids.each do |pid|
        return false unless process_alive?(pid)
      end

      true
    end

    def self.any_alive?(pids)
      pids_alive(pids).any?
    end

    def self.pids_alive(pids)
      pids.select { |pid| process_alive?(pid) }
    end

    def self.process_alive?(pid)
      # Signal 0 tests whether the process exists and we have access to send signals
      # but is otherwise a noop (doesn't actually send a signal to the process)
      signal(pid, 0)
    end

    def self.write_pid(path)
      File.open(path, 'w') do |handle|
        handle.write(Process.pid.to_s)
      end
    end
  end
end
