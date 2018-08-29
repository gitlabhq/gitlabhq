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

    def self.parse_queues(array)
      array.map { |chunk| chunk.split(',') }
    end

    # Starts Sidekiq workers for the pairs of processes.
    #
    # Example:
    #
    #     start([ ['foo'], ['bar', 'baz'] ], :production)
    #
    # This would start two Sidekiq processes: one processing "foo", and one
    # processing "bar" and "baz".
    #
    # queues - An Array containing Arrays. Each sub Array should specify the
    #          queues to use for a single process.
    #
    # directory - The directory of the Rails application.
    #
    # Returns an Array containing the PIDs of the started processes.
    def self.start(queues, env, directory = Dir.pwd, max_concurrency = 50, dryrun: false)
      queues.map { |pair| start_sidekiq(pair, env, directory, max_concurrency, dryrun: dryrun) }
    end

    # Starts a Sidekiq process that processes _only_ the given queues.
    #
    # Returns the PID of the started process.
    def self.start_sidekiq(queues, env, directory = Dir.pwd, max_concurrency = 50, dryrun: false)
      cmd = %w[bundle exec sidekiq]
      cmd << "-c #{self.concurrency(queues, max_concurrency)}"
      cmd << "-e#{env}"
      cmd << "-gqueues: #{queues.join(', ')}"
      cmd << "-r#{directory}"

      queues.each do |q|
        cmd << "-q#{q},1"
      end

      if dryrun
        puts "Sidekiq command: #{cmd}"
        return
      end

      pid = Process.spawn(
        { 'ENABLE_SIDEKIQ_CLUSTER' => '1' },
        *cmd,
        err: $stderr,
        out: $stdout
      )

      wait_async(pid)

      pid
    end

    def self.concurrency(queues, max_concurrency)
      if max_concurrency.positive?
        [queues.length + 1, max_concurrency].min
      else
        queues.length + 1
      end
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
        return false unless signal(pid, 0)
      end

      true
    end

    def self.write_pid(path)
      File.open(path, 'w') do |handle|
        handle.write(Process.pid.to_s)
      end
    end
  end
end
