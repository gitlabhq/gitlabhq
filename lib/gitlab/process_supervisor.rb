# frozen_string_literal: true

require_relative './daemon'

module Gitlab
  # Given a set of process IDs, the supervisor can monitor processes
  # for being alive and invoke a callback if some or all should go away.
  # The receiver of the callback can then act on this event, for instance
  # by restarting those processes or performing clean-up work.
  #
  # The supervisor will also trap termination signals if provided and
  # propagate those to the supervised processes. Any supervised processes
  # that do not terminate within a specified grace period will be killed.
  class ProcessSupervisor < Gitlab::Daemon
    DEFAULT_HEALTH_CHECK_INTERVAL_SECONDS = 5
    DEFAULT_TERMINATE_INTERVAL_SECONDS = 1
    DEFAULT_TERMINATE_TIMEOUT_SECONDS = 10

    attr_reader :alive

    def initialize(
      health_check_interval_seconds: DEFAULT_HEALTH_CHECK_INTERVAL_SECONDS,
      check_terminate_interval_seconds: DEFAULT_TERMINATE_INTERVAL_SECONDS,
      terminate_timeout_seconds: DEFAULT_TERMINATE_TIMEOUT_SECONDS,
      term_signals: [],
      forwarded_signals: [],
      **options)
      super(**options)

      @term_signals = term_signals
      @forwarded_signals = forwarded_signals
      @health_check_interval_seconds = health_check_interval_seconds
      @check_terminate_interval_seconds = check_terminate_interval_seconds
      @terminate_timeout_seconds = terminate_timeout_seconds

      @pids = Set.new
      @alive = false
    end

    # Starts a supervision loop for the given process ID(s).
    #
    # If any or all processes go away, the IDs of any dead processes will
    # be yielded to the given block, so callers can act on them.
    #
    # If the block returns a non-empty list of IDs, the supervisor will
    # start observing those processes instead. Otherwise it will shut down.
    def supervise(pid_or_pids, &on_process_death)
      @pids = Array(pid_or_pids).to_set
      @on_process_death = on_process_death

      trap_signals!

      start
    end

    # Shuts down the supervisor and all supervised processes with the given signal.
    def shutdown(signal = :TERM)
      return unless @alive

      stop_processes(signal)
    end

    def supervised_pids
      @pids
    end

    private

    def start_working
      @alive = true
    end

    def stop_working
      @alive = false
    end

    def run_thread
      while @alive
        check_process_health

        sleep(@health_check_interval_seconds)
      end
    end

    def check_process_health
      unless all_alive?
        existing_pids = live_pids.to_set # Capture this value for the duration of the block.
        dead_pids = @pids - existing_pids
        new_pids = Array(@on_process_death.call(dead_pids.to_a))
        @pids = existing_pids + new_pids.to_set
      end
    end

    def stop_processes(signal)
      # Set this prior to shutting down so that shutdown hooks which read `alive`
      # know the supervisor is about to shut down.
      stop_working

      # Shut down supervised processes.
      signal_all(signal)
      wait_for_termination
    end

    def trap_signals!
      ProcessManagement.trap_signals(@term_signals) do |signal|
        stop_processes(signal)
      end

      ProcessManagement.trap_signals(@forwarded_signals) do |signal|
        signal_all(signal)
      end
    end

    def wait_for_termination
      deadline = monotonic_time + @terminate_timeout_seconds
      sleep(@check_terminate_interval_seconds) while continue_waiting?(deadline)

      hard_stop_stuck_pids
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_second)
    end

    def continue_waiting?(deadline)
      any_alive? && monotonic_time < deadline
    end

    def signal_all(signal)
      ProcessManagement.signal_processes(@pids, signal)
    end

    def hard_stop_stuck_pids
      ProcessManagement.signal_processes(live_pids, "-KILL")
    end

    def any_alive?
      ProcessManagement.any_alive?(@pids)
    end

    def all_alive?
      ProcessManagement.all_alive?(@pids)
    end

    def live_pids
      ProcessManagement.pids_alive(@pids)
    end
  end
end
