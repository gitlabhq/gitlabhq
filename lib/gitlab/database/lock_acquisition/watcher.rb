# frozen_string_literal: true

module Gitlab
  module Database
    module LockAcquisition
      # Watches a session that is blocked acquiring heavyweight locks, from
      # a second connection.
      #
      # Observe: log each Observation (the blockers ahead of the watched
      # session and the queue forming behind it) while the wait is
      # happening, not post-mortem. Protect: feed every observation into
      # the DamageBill and cancel the watched session's OWN wait (never any
      # other backend) when a trip fires. Trip reasons, in evaluation order:
      #   :pool_exhaustion  - queue depth reached the capacity ceiling
      #   :accumulated_wait - the window or run bill is spent
      #   :table_too_hot    - the bill filled on the first poll of a window
      # A victims trip (metering rollbacks of sessions queued behind us) can
      # be added once production data supports a fair ceiling.
      #
      # The watcher never extends any timeout: the watched session's own
      # lock_timeout remains the hard ceiling even if every watcher
      # connection dies. Losing observation while armed cancels the watched
      # wait (the dying act) rather than letting the hold run blind. The
      # loop handles one event at a time (a poll, an attempt boundary, a
      # settle), so nothing observed during one attempt can act on the
      # next, and no attempt starts without the loop's answer.
      class Watcher
        # A misdeclared table would silently pass validation while the real
        # table goes unwatched; fail closed so the caller demotes.
        UnresolvedTablesError = Class.new(StandardError)
        # Raised when the loop does not answer #begin_attempt or #settle
        # within the handoff deadline, or has already exited: a wedged or
        # dead watcher must never let a new attempt start unsupervised.
        SupervisionStalledError = Class.new(StandardError)

        # None of the values below are configurable at runtime, on purpose:
        # each encodes a reviewed safety judgment, documented where defined.

        # pg_blocking_pids takes exclusive access to the lock manager's
        # shared state; do not poll tighter than 1s.
        POLL_INTERVAL_S = 1
        LOG_EVERY_POLLS = 5
        # Bounds each poll statement so a sick watcher is detected fast:
        # with MAX_POLL_FAILURES = 1 the worst interval from the last good
        # observation to the dying-act cancel is ~3.5s.
        STATEMENT_TIMEOUT_S = 0.5
        STATEMENT_TIMEOUT = "#{(STATEMENT_TIMEOUT_S * 1000).to_i}ms".freeze
        JOIN_TIMEOUT_S = 5
        # Covers pool checkout (5s default) plus prepare and the first poll
        # (500ms statement_timeout each).
        ARM_TIMEOUT_S = 10
        # One transient poll failure only skips a beat (sessions recover
        # from statement errors in autocommit); the next consecutive
        # failure degrades.
        MAX_POLL_FAILURES = 1

        attr_reader :degraded_reason

        def initialize(pool:, ddl_session:, tables:, pool_capacity:, logger:, log_params: {})
          @pool = pool
          @ddl_pid = Integer(ddl_session.fetch(:pid))
          @ddl_backend_start = ddl_session.fetch(:backend_start).to_s
          @tables = Array(tables).map(&:to_s)
          # Trip at 40% of the pool (60% headroom before real exhaustion),
          # never below 2 stuck sessions and never above 20.
          @count_ceiling = (Integer(pool_capacity) * 0.4).floor.clamp(2, 20)
          @logger = logger
          @log_params = log_params
          @inbox = Queue.new
          @arming_signal = Queue.new
          @armed = false
          # Covers the worst event the loop may be finishing before it can
          # answer: a poll plus a fallback cancel (pool checkout + capped
          # statements).
          @handoff_deadline_s = pool.checkout_timeout + (5 * STATEMENT_TIMEOUT_S) + POLL_INTERVAL_S + 1
          @discard_connection = false
          @polls = 0
          @consecutive_poll_failures = 0
          @session_suspect = false
          @bill = DamageBill.new
          @session_guard = SessionGuard.new(pool: pool)
          @last_depth = 0
          @last_in_lock_wait = false
          @peak_queued_waiters = 0
          @peak_unfiltered_waiters = 0
          @blocker_pids_seen = Set.new
          @last_blocking_pids = []
        end

        def start
          @thread = Thread.new do
            Thread.current.name = 'lock-acq-watcher'
            run_loop
          end

          # A freshly spawned thread is alive long before it can observe
          # anything, and a held window must never run unwatched: block
          # until the first poll succeeds, or degrade so the caller demotes.
          @degraded_reason ||= 'watcher failed to arm in time' unless @arming_signal.pop(timeout: ARM_TIMEOUT_S)

          self
        rescue StandardError => e
          @degraded_reason = "#{e.class}: #{e.message}"
          self
        end

        def stop
          begin
            # Also wakes the loop from its poll wait: the caller may be
            # holding an ACCESS EXCLUSIVE lock while it waits for this join.
            @inbox.push([:stop])
          rescue ClosedQueueError
            nil # the loop already exited
          end

          if @thread && @thread.join(JOIN_TIMEOUT_S).nil?
            @discard_connection = true
            @thread.kill

            if @thread.join(1).nil?
              # Wedged in a native call: the connection stays checked out
              # (a stranded pool slot) until the call returns and the
              # dying ensure discards it.
              log(message: 'Lock acquisition watcher thread survived kill; connection slot stranded')
            end

            @degraded_reason ||= 'watcher thread killed after join timeout'
          end

          log_summary
        end

        # Called by the retry loop before each attempt; returns once the loop
        # has finished any poll in flight and reset its per-attempt state.
        def begin_attempt
          answer = request(:begin_attempt)
          return if answer == :ok

          raise SupervisionStalledError, answer ? 'watcher has stopped' : 'watcher did not answer in time'
        end

        # Called by the retry loop when an attempt ends in an error: the
        # attempt's verdict as the loop held it when it answered, after any
        # evaluation in flight finished.
        def settle
          answer = request(:settle)
          raise SupervisionStalledError, 'watcher did not answer in time' if answer.nil?

          # An exited loop can no longer change its final verdict.
          answer == :closed ? verdict : answer
        end

        def healthy?
          @degraded_reason.nil? && !!@thread&.alive?
        end

        private

        attr_reader :pool, :ddl_pid, :ddl_backend_start, :tables, :logger, :log_params, :bill, :protection,
          :session_guard

        def verdict
          protection&.verdict || Protection::NO_VERDICT
        end

        # The loop's answer: nil when it did not answer before the deadline,
        # :closed when it has exited.
        def request(kind)
          reply = Queue.new
          @inbox.push([kind, reply])
          reply.pop(timeout: @handoff_deadline_s)
        rescue ClosedQueueError
          :closed
        end

        def run_loop
          connection = session_guard.checkout

          begin
            prepare(connection)
            poll(connection)
            @armed = true
            @arming_signal.push(true)
            serve(connection)
          rescue StandardError => e
            record_degraded(e)
            # Dying act: an armed watcher that goes blind must not leave
            # the hold running unwatched; end the watched wait instead.
            watch_loss_cancel(connection)
          ensure
            release_connection(connection)
          end
        rescue StandardError => e
          record_degraded(e)
        ensure
          # Unblocks the arming pop in #start when the loop failed before
          # its first poll; a stale extra value is never read.
          @arming_signal.push(false)
          close_inbox
        end

        def serve(connection)
          deadline = monotonic_now + POLL_INTERVAL_S

          loop do
            kind, reply = @inbox.pop(timeout: [deadline - monotonic_now, 0].max)

            case kind
            when nil
              resilient_poll(connection)
              deadline = monotonic_now + POLL_INTERVAL_S
            when :begin_attempt
              start_attempt
              reply.push(:ok)
            when :settle
              reply.push(verdict)
            when :stop
              break
            end
          end
        end

        # The last observation belongs to the previous attempt, so a blind
        # interval right after this bills and blames nothing.
        def start_attempt
          protection.reset_attempt!
          bill.new_attempt!(monotonic_now)
          @last_depth = 0
          @last_in_lock_wait = false
        end

        # Answers whatever is still queued so no caller waits out the
        # deadline on a loop that is gone.
        def close_inbox
          @inbox.close

          until @inbox.empty?
            _kind, reply = @inbox.pop
            reply&.push(:closed)
          end
        end

        def record_degraded(error)
          @degraded_reason ||= "#{error.class}: #{error.message}"
          log(message: 'Lock acquisition watcher degraded', watcher_error: @degraded_reason)
        end

        def release_connection(connection)
          session_guard.release(connection, discard: @discard_connection)
        end

        def prepare(connection)
          session_guard.harden(connection)

          @quoted_backend_start = "#{connection.quote(ddl_backend_start)}::timestamptz"

          @db_oid = connection.select_value(
            'SELECT oid FROM pg_database WHERE datname = current_database()'
          ).to_i

          # Validation only: the bill is metered against the DDL session's
          # own lock set at poll time, not against these names.
          missing = tables.reject { |table| connection.table_exists?(table) }
          raise UnresolvedTablesError, "watched tables do not exist: #{missing.join(', ')}" if missing.any?

          @relation_count = relation_count(connection)

          @protection = Protection.new(
            bill: bill, count_ceiling: @count_ceiling, pool: pool, ddl_pid: ddl_pid,
            quoted_backend_start: @quoted_backend_start, logger: logger, log_params: log_params
          )
        end

        def poll(connection)
          @polls += 1
          observation = Observation.capture(
            connection, ddl_pid: ddl_pid, db_oid: @db_oid, quoted_backend_start: @quoted_backend_start
          )

          # The ceiling counts every waiter behind us regardless of lock
          # type: a backend stuck on a row lock occupies a pool slot too.
          protection.ceiling_trip(connection, observation.unfiltered_waiters, observation.in_lock_wait?)
          bill.accrue(observation.queued_waiters, observation.in_lock_wait?)
          track(observation)
          log_observation(observation)
          protection.blindness_watch_loss(connection, armed: @armed)
          protection.budget_trip(connection, observation.queued_waiters, observation.in_lock_wait?)

          @last_depth = observation.queued_waiters
          @last_in_lock_wait = observation.in_lock_wait?
        end

        # Only the arming poll is strict. Afterwards a blind interval still
        # accrues at the last observed depth, and blindness during a lock
        # wait routes to watch loss immediately.
        def resilient_poll(connection)
          # An adapter-level reconnect after a tolerated failure resurrects
          # the session without our safety SETs; re-assert them before
          # trusting another poll.
          session_guard.reassert(connection) if @session_suspect
          poll(connection)
          @consecutive_poll_failures = 0
          @session_suspect = false
        rescue StandardError => e
          bill.accrue(@last_depth, @last_in_lock_wait)
          protection.blindness_watch_loss(connection, armed: @armed)

          @consecutive_poll_failures += 1
          raise if @consecutive_poll_failures > MAX_POLL_FAILURES

          @session_suspect = true
          log(message: 'Lock acquisition watcher poll failed', watcher_error: "#{e.class}: #{e.message}")
        end

        def watch_loss_cancel(connection)
          protection&.watch_loss_cancel(connection, armed: @armed)
        end

        def track(observation)
          @peak_queued_waiters = [@peak_queued_waiters, observation.queued_waiters].max
          @peak_unfiltered_waiters = [@peak_unfiltered_waiters, observation.unfiltered_waiters].max
          # pid 0 is a prepared transaction, not a signallable session.
          @blocker_pids_seen.merge(observation.blocking_pids - [0])
        end

        def log_observation(observation)
          changed = observation.blocking_pids != @last_blocking_pids
          @last_blocking_pids = observation.blocking_pids
          return unless changed || (@polls % LOG_EVERY_POLLS) == 0

          log(
            message: 'Lock acquisition watch',
            blocking_pids: observation.blocking_pids,
            queued_waiters: observation.queued_waiters,
            unfiltered_waiters: observation.unfiltered_waiters,
            window_spent: bill.window_spent.round(2),
            ddl_wait_event_type: observation.wait_event_type
          )
        end

        def log_summary
          log(
            message: 'Lock acquisition watch finished',
            polls: @polls,
            relations: @relation_count,
            peak_queued_waiters: @peak_queued_waiters,
            peak_unfiltered_waiters: @peak_unfiltered_waiters,
            run_spent: bill.run_spent.round(2),
            count_ceiling: @count_ceiling,
            distinct_blocker_pids: @blocker_pids_seen.size,
            cancel_requested: verdict.canceled,
            trip_reason: verdict.trip_reason,
            watcher_degraded: @degraded_reason.present?
          )
        end

        # Informational: lock_timeout applies per lock acquisition, so with
        # more than two relations the 7s rungs can cumulatively cross the
        # 15s statement_timeout and fail untyped; logged so that failure is
        # diagnosable. A partitioned parent expands to every member of its
        # partition tree; a plain table counts as one (pg_partition_tree
        # returns no rows for it, hence the GREATEST).
        def relation_count(connection)
          connection.select_value(<<~SQL).to_i
            SELECT COALESCE(sum(GREATEST(p.members, 1)), 0)
            FROM unnest(ARRAY[#{quoted_table_names(connection)}]::text[]) AS t,
              LATERAL (SELECT count(*) AS members FROM pg_partition_tree(to_regclass(t))) AS p
          SQL
        end

        def quoted_table_names(connection)
          tables.map { |table| connection.quote(table) }.join(', ')
        end

        def monotonic_now
          Gitlab::Metrics::System.monotonic_time
        end

        def log(params)
          logger.info(log_params.merge(params))
        end
      end
    end
  end
end
