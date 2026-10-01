# frozen_string_literal: true

module Gitlab
  module Database
    module LockAcquisition
      # Measures the harm a lock wait causes to other sessions, in
      # blocked-backend-seconds: on every poll it charges (sessions
      # currently queued behind the watched session) x (seconds since the
      # previous poll). The depth at the end of each interval is what gets
      # charged, so a queue that grew mid-interval is charged slightly
      # high, never low.
      #
      # Two running totals: the window bill covers one lock attempt and
      # resets between attempts; the run bill covers the whole migration
      # and never resets. No I/O and no threads here; the Watcher reads
      # the totals and decides what to do.
      class DamageBill
        # Maximum blocked-backend-seconds one attempt may charge. 10 equals
        # the cost of a single 2s rung of DEFAULT_TIMING_CONFIGURATION once
        # blocking arrivals reach ~5/s; at higher rates that rung costs
        # more while this cap stays fixed, so the budget only gets stricter
        # relative to the ladder as traffic grows. The true per-attempt
        # bound is this budget plus up to one poll interval of arrivals
        # accrued before the next measurement. Deliberately not scaled to
        # server size: a second of a blocked user's time costs the same on
        # any deployment.
        WINDOW_BUDGET = 10.0
        # The whole run may spend at most double one window, so several
        # under-budget attempts cannot add up to unlimited total harm.
        RUN_BUDGET_MULTIPLIER = 2
        # If more time than this passed between two measurements, the
        # watcher was blind for part of the interval. Derived from the
        # healthy worst case (a 1s sleep plus a query bounded at 0.5s) plus
        # 0.5s of headroom for scheduler and GC jitter, so an ordinary slow
        # cycle never reads as blindness. Time beyond the cap is never charged;
        # the Watcher treats it as lost supervision and ends the hold instead.
        RECTANGLE_WIDTH_CAP_S = Watcher::POLL_INTERVAL_S + Watcher::STATEMENT_TIMEOUT_S + 0.5

        attr_reader :window_spent, :run_spent

        def initialize
          @window_spent = 0.0
          @run_spent = 0.0
          @window_polls = 0
          @last_rectangle_capped = false
          @attempt_started_at = nil
          @last_accrual_at = nil
        end

        # Called when the retry loop starts a new attempt. The next accrual
        # bills from started_at instead of from the previous measurement,
        # so the sleep between attempts (when nothing was blocked) is never
        # charged; only that first accrual gets this adjustment.
        def new_attempt!(started_at)
          reset_window
          @attempt_started_at = started_at
        end

        def accrue(depth, in_lock_wait)
          now = monotonic_now
          from = @last_accrual_at || now

          if @attempt_started_at
            from = @attempt_started_at if @attempt_started_at > from
            @attempt_started_at = nil
          end

          width = now - from
          @last_accrual_at = now

          unless in_lock_wait
            reset_window
            return
          end

          @window_polls += 1
          @last_rectangle_capped = width > RECTANGLE_WIDTH_CAP_S
          cost = depth * [width, RECTANGLE_WIDTH_CAP_S].min
          @window_spent += cost
          @run_spent += cost
        end

        # True at most once per over-wide interval: reading the flag also
        # clears it, so one blind interval triggers exactly one reaction.
        def consume_capped_interval?
          capped = @last_rectangle_capped
          @last_rectangle_capped = false
          capped
        end

        def run_exhausted?
          @run_spent >= WINDOW_BUDGET * RUN_BUDGET_MULTIPLIER
        end

        def window_exhausted?
          @window_spent >= WINDOW_BUDGET
        end

        # The window's very first measurement already spent the whole
        # budget: arrivals are too fast for any watched hold, not just for
        # this crowded moment.
        def filled_on_first_poll?
          @window_polls == 1
        end

        private

        def reset_window
          @window_spent = 0.0
          @window_polls = 0
          @last_rectangle_capped = false
        end

        def monotonic_now
          Gitlab::Metrics::System.monotonic_time
        end
      end
    end
  end
end
