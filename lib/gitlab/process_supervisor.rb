# frozen_string_literal: true

module Gitlab
  # Given a set of process IDs, the supervisor can monitor processes
  # for being alive and invoke a callback if some or all should go away.
  # The receiver of the callback can then act on this event, for instance
  # by restarting those processes or performing clean-up work.
  #
  # The supervisor will also trap termination signals if provided and
  # propagate those to the supervised processes. Any supervised processes
  # that do not terminate within a specified grace period will be killed.
  class ProcessSupervisor
    DEFAULT_HEALTH_CHECK_INTERVAL_SECONDS = 5
    DEFAULT_TERMINATE_INTERVAL_SECONDS = 1
    DEFAULT_TERMINATE_TIMEOUT_SECONDS = 10

    attr_reader :alive

    def initialize(
      health_check_interval_seconds: DEFAULT_HEALTH_CHECK_INTERVAL_SECONDS,
      check_terminate_interval_seconds: DEFAULT_TERMINATE_INTERVAL_SECONDS,
      terminate_timeout_seconds: DEFAULT_TERMINATE_TIMEOUT_SECONDS,
      term_signals: %i(INT TERM),
      forwarded_signals: [])

      @term_signals = term_signals
      @forwarded_signals = forwarded_signals
      @health_check_interval_seconds = health_check_interval_seconds
      @check_terminate_interval_seconds = check_terminate_interval_seconds
      @terminate_timeout_seconds = terminate_timeout_seconds
    end

    # Starts a supervision loop for the given process ID(s).
    #
    # If any or all processes go away, the IDs of any dead processes will
    # be yielded to the given block, so callers can act on them.
    #
    # If the block returns a non-empty list of IDs, the supervisor will
    # start observing those processes instead. Otherwise it will shut down.
    def supervise(pid_or_pids, &on_process_death)
      @pids = Array(pid_or_pids)

      trap_signals!

      @alive = true
      while @alive
        sleep(@health_check_interval_seconds)

        check_process_health(&on_process_death)
      end
    end

    private

    def check_process_health(&on_process_death)
      unless all_alive?
        dead_pids = @pids - live_pids
        @pids = Array(yield(dead_pids))
        @alive = @pids.any?
      end
    end

    def trap_signals!
      ProcessManagement.trap_signals(@term_signals) do |signal|
        @alive = false
        signal_all(signal)
        wait_for_termination
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
