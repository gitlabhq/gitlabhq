require 'open3'

module Gitlab
  module SidekiqCluster
    # The signals that should terminate both the master and workers.
    TERMINATE_SIGNALS = %i(INT TERM)

    # The signals that should simply be forwarded to the workers.
    FORWARD_SIGNALS = %i(TTIN USR1 USR2 HUP)

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

    def self.signal_threads(threads, signal)
      threads.each { |thread| signal(thread.pid, signal) }
    end

    def self.parse_queues(array)
      array.map { |chunk| chunk.split(',') }
    end

    # Starts Sidekiq workers for the pairs of threads.
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
    # Returns an Array containing the threads monitoring each process.
    def self.start(queues, env)
      queues.map { |pair| start_sidekiq(pair, env) }
    end

    # Starts a Sidekiq process that processes _only_ the given queues.
    def self.start_sidekiq(queues, env)
      switches = queues.map { |q| "-q #{q},1" }

      Open3.popen3({ 'ENABLE_SIDEKIQ_CLUSTER' => '1' },
                   'bundle',
                   'exec',
                   'sidekiq',
                   "-c #{queues.length + 1}",
                   "-e#{env}",
                   "-gqueues: #{queues.join(', ')}",
                   *switches).last
    end

    # Returns true if all the processes/threads are alive.
    def self.all_alive?(threads)
      threads.each do |thread|
        return false unless signal(thread.pid, 0)
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
