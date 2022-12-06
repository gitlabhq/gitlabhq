# frozen_string_literal: true

module Gitlab
  module ProcessManagement
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

    # Traps the given signals with the given command.
    #
    # Example:
    #
    #     modify_signals(%i(HUP TERM), 'DEFAULT')
    def self.modify_signals(signals, command)
      signals.each { |signal| trap(signal, command) }
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
      return false if pid.nil?

      # Signal 0 tests whether the process exists and we have access to send signals
      # but is otherwise a noop (doesn't actually send a signal to the process)
      signal(pid, 0)
    end

    def self.process_died?(pid)
      !process_alive?(pid)
    end

    def self.write_pid(path)
      File.open(path, 'w') do |handle|
        handle.write(Process.pid.to_s)
      end
    end
  end
end
