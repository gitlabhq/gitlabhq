# frozen_string_literal: true

module Gitlab
  module Database
    module LockAcquisition
      # Decides when a watched hold must end, and ends it: checks every
      # observation against the pool ceiling and the DamageBill, and when
      # a limit is crossed (or the watcher loses sight) it cancels the
      # watched session's OWN lock wait, never any other session.
      #
      # The cancel statement carries its own safety conditions: it only
      # matches a session with the exact pid AND start time that is
      # actively waiting for a lock, so it can never signal an unrelated
      # session. The check and the signal are not atomic: a cancel racing
      # the acquisition can land just after the lock is granted and abort
      # the run instead of the wait, which is accepted (the watcher's
      # decision to abort already stands). Delivery is retried once on a
      # fresh connection, because the signal matters most exactly when
      # the polling connection just died.
      class Protection
        # One attempt's outcome, replaced whole so a reader never sees half
        # an update: trip_reason is the trip decided this attempt; canceled
        # and watch_lost mean that cancel was confirmed delivered.
        Verdict = Data.define(:trip_reason, :canceled, :watch_lost)
        NO_VERDICT = Verdict.new(trip_reason: nil, canceled: false, watch_lost: false)

        attr_reader :verdict

        def initialize(bill:, count_ceiling:, pool:, ddl_pid:, quoted_backend_start:, logger:, log_params:)
          @bill = bill
          @count_ceiling = count_ceiling
          @pool = pool
          @ddl_pid = ddl_pid
          @quoted_backend_start = quoted_backend_start
          @logger = logger
          @log_params = log_params
          @verdict = NO_VERDICT
        end

        def reset_attempt!
          @verdict = NO_VERDICT
        end

        # The exhaustion cliff is a tripwire, checked before any billing.
        def ceiling_trip(connection, depth, in_lock_wait)
          return unless in_lock_wait && acting?
          return if depth < count_ceiling

          request_cancel(connection, :pool_exhaustion, depth)
        end

        # A too-wide measuring interval means we were not watching for part
        # of it; that ends the hold immediately, no matter how much budget
        # is left. The bill only flags such intervals while the session was
        # waiting, so no extra wait check is needed here.
        def blindness_watch_loss(connection, armed:)
          return unless bill.consume_capped_interval?

          watch_loss_cancel(connection, armed: armed)
        end

        def budget_trip(connection, depth, in_lock_wait)
          return unless in_lock_wait && acting?

          if bill.run_exhausted?
            request_cancel(connection, :accumulated_wait, depth)
          elsif bill.window_exhausted?
            reason = bill.filled_on_first_poll? ? :table_too_hot : :accumulated_wait
            request_cancel(connection, reason, depth)
          end
        end

        def watch_loss_cancel(connection, armed:)
          return unless armed && acting?

          signalled = signal_own_cancel_with_fallback(connection)
          # Unconfirmed delivery claims nothing: an operator cancel must
          # never be mistaken for ours and absorbed.
          @verdict = verdict.with(watch_lost: true) if signalled

          log(message: 'Lock acquisition watcher canceled watched wait on watch loss', signalled: !!signalled)
        end

        private

        attr_reader :bill, :count_ceiling, :pool, :ddl_pid, :quoted_backend_start, :logger, :log_params

        # Once a cancel landed there is nothing left to do; an undelivered
        # decision (or a watch loss that ended the wait first) is retried or
        # respected on the next trip.
        def acting?
          !verdict.canceled && !verdict.watch_lost
        end

        # The attempt's first decision keeps its reason; later trips only
        # retry its delivery.
        def request_cancel(connection, reason, depth)
          @verdict = verdict.with(trip_reason: verdict.trip_reason || reason)
          # The signal itself can hit a dying connection; retried once on a
          # fresh session so the emergency is not lost to a blip.
          signalled = signal_own_cancel_with_fallback(connection)
          @verdict = verdict.with(canceled: true) if signalled

          log(
            message: 'Lock acquisition watcher canceling own session',
            trip_reason: verdict.trip_reason,
            signalled: !!signalled,
            queued_waiters: depth,
            window_spent: bill.window_spent.round(2),
            run_spent: bill.run_spent.round(2),
            count_ceiling: count_ceiling
          )
        end

        def signal_own_cancel(connection)
          connection.select_value(<<~SQL)
            SELECT pg_cancel_backend(pid)
            FROM pg_stat_activity
            WHERE pid = #{ddl_pid}
              AND backend_start = #{quoted_backend_start}
              AND state = 'active'
              AND wait_event_type = 'Lock'
          SQL
        end

        def signal_own_cancel_with_fallback(connection)
          signal_own_cancel(connection)
        rescue StandardError
          fresh_connection_cancel
        end

        # The fresh session goes back to the pool only after clean
        # completion; an error mid-statement leaves protocol state unknown,
        # so those paths discard it. SET LOCAL keeps the timeout
        # transaction-scoped.
        def fresh_connection_cancel
          # Bounded checkout (seconds): the emergency fallback must not hang
          # the watcher waiting on a busy pool; no connection quickly means
          # "no signal sent", which callers report honestly.
          fresh = pool.checkout(2)
          signalled = nil
          clean = false

          begin
            fresh.transaction do
              fresh.execute("SET LOCAL statement_timeout = '#{Watcher::STATEMENT_TIMEOUT}'")
              signalled = signal_own_cancel(fresh)
            end

            clean = true
          ensure
            clean ? pool.checkin(fresh) : SessionGuard.remove_and_disconnect(pool, fresh)
          end

          signalled
        rescue StandardError
          nil
        end

        def log(params)
          logger.info(log_params.merge(params))
        end
      end
    end
  end
end
