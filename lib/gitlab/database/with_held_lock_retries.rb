# frozen_string_literal: true

module Gitlab
  module Database
    # {WithLockRetries} in hold mode: a short canary attempt, then a few long
    # attempts watched from a second connection by {LockAcquisition::Watcher},
    # which cancels our own wait when a damage budget or pool ceiling trips.
    # If the watcher cannot arm, or is found dead before an attempt, the run
    # continues on the default ladder. Losing it during a wait, or finding our
    # session on another backend, raises {WatchLostError}.
    #
    # Only for sessions connected directly to PostgreSQL (migrations): behind
    # PgBouncer the pooled backend pid is not ours to watch. It assumes no outer
    # transaction: a retry cannot release locks the caller's transaction holds.
    class WithHeldLockRetries < WithLockRetries
      # Raised when the watcher ended the attempt because the damage budget or
      # a guard tripped. Not retried in process; #reason says how to retry:
      #   :accumulated_wait - crowded now, retry after a pause
      #   :pool_exhaustion  - the queue behind us reached the connection ceiling
      #   :table_too_hot    - too busy for any watched hold; needs a quiet window
      class WaiterPileupError < StandardError
        attr_reader :reason

        def initialize(message = nil, reason: nil)
          @reason = reason
          super(message)
        end
      end
      # Raised when the watcher canceled our wait as its dying act, stopped
      # answering, or lost our session to a reconnect. Not retried in process, so
      # a racing operator cancel still stops the run; unlike {WaiterPileupError}
      # it does not mean congestion.
      WatchLostError = Class.new(StandardError)

      # The 1s canary samples the real queue with bounded exposure. 7s outlasts
      # gprd's 5s deadlock_timeout (log_lock_waits fires, plain autovacuum yields)
      # yet keeps both waits of a LOCK TABLE a, b under the 15s statement_timeout.
      HOLD_TIMING_CONFIGURATION = ([[1.second, 1.second]] + ([[7.seconds, 2.seconds]] * 3)).freeze

      # Builds a hold-mode runner for the tables the block locks.
      #
      # @param [Array<String, Symbol>] tables the tables the block locks; the
      #   watcher validates them, and with none the run does not hold
      # @param [Hash] kwargs as for {WithLockRetries#initialize}, except
      #   timing_configuration
      def initialize(tables:, **kwargs)
        raise ArgumentError, 'hold mode brings its own timing_configuration' if kwargs.key?(:timing_configuration)

        super(**kwargs)

        @tables = Array(tables).map(&:to_s)
        @hold_mode = @tables.any?

        return if @hold_mode

        log(message: 'Hold mode requested but unavailable, using default timing')
      end

      # Runs the block as {WithLockRetries#run} does, with the lock waits held
      # and watched while hold mode is armed.
      #
      # @param [Boolean] raise_on_exhaustion must be true: hold must never fall
      #   through to the timeout-free final attempt
      # @param [Proc] block code that takes the locks on the declared tables
      def run(raise_on_exhaustion: false, &block)
        raise 'no block given' unless block
        # Checked before any env gate so it fails deterministically.
        raise ArgumentError, 'WithHeldLockRetries requires raise_on_exhaustion: true' unless raise_on_exhaustion

        if lock_retries_disabled?
          log(message: 'DISABLE_LOCK_RETRIES environment variable is true, bypassing hold mode')

          return super
        end

        start_watcher if hold_mode?

        super
      rescue LockAcquisition::Watcher::SupervisionStalledError
        raise_watch_lost!
      ensure
        stop_watcher
      end

      private

      def log_params
        super.merge(tables: @tables)
      end

      # A demoted run continues on the default ladder from the current iteration.
      def timing_configuration
        hold_mode? ? HOLD_TIMING_CONFIGURATION : super
      end

      # Classifies the attempt's error before {WithLockRetries#run} issues any
      # further statement on this session.
      def run_block_with_lock_timeout
        # A watcher that died since the previous attempt demotes the run instead
        # of letting this one start unwatched.
        demote_hold_mode!('watcher unhealthy') if @watcher && !@watcher.healthy?
        @watcher&.begin_attempt

        super
      rescue ActiveRecord::LockWaitTimeout
        raise_for_watcher_verdict!(lock_timeout: true)
        log_blocker_census(exhausted: true) unless retry_with_lock_timeout?
        raise
      rescue ActiveRecord::Deadlocked => e
        raise unless hold_mode?

        # Held attempts outlast deadlock_timeout, so a lock cycle aborts whichever
        # waiter's deadlock check fires first: ours is retried here like a lock
        # timeout, and an app transaction can be the victim instead.
        log(message: 'Held attempt ended in a deadlock', current_iteration: current_iteration)
        raise_for_watcher_verdict!(lock_timeout: true)
        log_blocker_census(exhausted: true) unless retry_with_lock_timeout?
        raise ActiveRecord::LockWaitTimeout, "deadlock during a held attempt: #{e.message}"
      # rubocop:disable Database/RescueQueryCanceled -- re-raised unless our own watcher deliberately canceled our wait
      rescue ActiveRecord::QueryCanceled
        # rubocop:enable Database/RescueQueryCanceled
        raise_for_watcher_verdict!(lock_timeout: false)
        raise
      end

      # Checked after SET LOCAL, where Rails can no longer reconnect silently. A new
      # backend means our session was killed (operator, failover): stop, as for an
      # operator cancel, rather than hold on a backend the watcher never saw.
      def run_block
        backend_pid = @watcher && Integer(connection.select_value('SELECT pg_backend_pid()'))
        if backend_pid && backend_pid != @watched_pid
          log(message: 'Hold session moved to a new backend', watched_pid: @watched_pid, backend_pid: backend_pid)
          raise_watch_lost!
        end

        super
      end

      def wait_until_next_retry
        log_blocker_census

        super
      end

      def reset_db_settings
        super
      rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished => e
        # Runs on error paths where the session may be aborted or gone; a failed
        # RESET must not mask the original error (both SETs are LOCAL anyway).
        log(message: 'Failed to reset db settings', Labkit::Fields::ERROR_TYPE => e.class.to_s)
      end

      # Hold's few attempts keep the census volume trivially bounded.
      def log_blocker_census(exhausted: false)
        return unless hold_mode?

        census = LockAcquisition::BlockerCensus.capture(connection, tables: @tables)

        log({
          message: 'Lock acquisition attempt blocked',
          current_iteration: current_iteration,
          lock_timeout_in_ms: current_lock_timeout_in_ms,
          exhausted: exhausted
        }.merge(census))
      end

      def hold_mode?
        @hold_mode
      end

      # Sizes the pool-exhaustion ceiling (a failed read demotes). Where app
      # traffic reaches PostgreSQL through PgBouncer this ceiling lands high, but
      # the damage budget still ends a pile-up within seconds, and the watcher caps it.
      def server_connection_capacity
        Integer(connection.select_value('SHOW max_connections'), 10)
      end

      def start_watcher
        # backend_start::text keeps microsecond precision; a Ruby Time
        # round-tripped through #to_s loses it and the watcher's
        # backend_start equality guards would never match.
        session = connection.select_one(
          'SELECT pg_backend_pid() AS pid, backend_start::text AS backend_start ' \
            'FROM pg_stat_activity WHERE pid = pg_backend_pid()'
        )
        @watched_pid = Integer(session['pid'])

        @watcher = LockAcquisition::Watcher.new(
          pool: connection.pool,
          ddl_session: { pid: session['pid'], backend_start: session['backend_start'] },
          tables: @tables,
          pool_capacity: server_connection_capacity,
          logger: logger,
          log_params: log_params
        )
        # Assigned before #start: an interrupt (Ctrl-C) while it arms still reaches stop_watcher.
        @watcher.start

        # #start blocks until the watcher's first successful poll.
        demote_hold_mode!("watcher failed to arm: #{@watcher.degraded_reason}") unless @watcher.healthy?
      rescue StandardError => e
        # A watcher failure must not fail the migration, and an unwatched hold
        # must not run; demoting is safe because no attempt has started yet.
        demote_hold_mode!("watcher failed to start: #{e.class}")
      end

      def demote_hold_mode!(reason)
        @hold_mode = false
        stop_watcher

        log(message: 'Hold mode demoted', demotion_reason: reason)
      end

      def stop_watcher
        @watcher&.stop
        @watcher = nil
      end

      # QueryCanceled counts only if the watcher delivered it, so operator cancels
      # propagate; LockWaitTimeout and Deadlocked are always ours, so the watcher's
      # decision stands even if they beat the delivery. Messages are localized, never matched.
      def raise_for_watcher_verdict!(lock_timeout:)
        return unless @watcher

        verdict = @watcher.settle
        raise_watch_lost! if verdict.watch_lost
        raise_waiter_pileup!(verdict.trip_reason) if lock_timeout ? verdict.trip_reason : verdict.canceled
      rescue LockAcquisition::Watcher::SupervisionStalledError
        raise_watch_lost!
      end

      # Both raisers log the census first: a typed deferral must carry its
      # own diagnostics (a canary trip would otherwise produce none).
      def raise_watch_lost!
        log_blocker_census
        reset_db_settings

        raise WatchLostError, 'hold supervision lost: the watcher canceled our wait, went silent, or lost our session'
      end

      def raise_waiter_pileup!(reason)
        log_blocker_census
        reset_db_settings

        raise WaiterPileupError.new("lock wait abandoned during acquisition (#{reason})", reason: reason)
      end
    end
  end
end
