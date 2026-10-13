# frozen_string_literal: true

module Gitlab
  module Database
    module LockAcquisition
      # One snapshot of the watched session's lock situation, read in a
      # single statement: which sessions block it (pg_blocking_pids), how
      # many sessions are queued behind it on the tables it holds or
      # awaits, and whether it is currently waiting for a lock at all.
      #
      # Both waiter counts only include sessions whose wait started at or
      # after ours (pg_locks.waitstart): sessions that were already blocked
      # by a third party before we arrived are not our damage. Of those,
      # queued_waiters keeps only sessions waiting for the tables themselves
      # (locktype = 'relation') and feeds the damage bill; row-level waiters
      # stuck behind them would clear when we leave, so the unfiltered count
      # feeds the pool-exhaustion ceiling and the logs.
      #
      # Known residual: the anchor is our CURRENT wait, so in a statement
      # locking several tables the queue forming on a table we already
      # acquired carries earlier waitstarts and is not counted. The guards
      # read low there, never high.
      class Observation
        # Must stay autocommit: inside a transaction pg_stat_activity
        # snapshots backend_start while wait_event_type reads live, so a
        # transaction-wrapped poll could pair values from different times.
        def self.capture(connection, ddl_pid:, db_oid:, quoted_backend_start:)
          new(connection.select_one(sql(ddl_pid, db_oid, quoted_backend_start)))
        end

        def self.sql(ddl_pid, db_oid, quoted_backend_start)
          <<~SQL
            SELECT
              (SELECT array_to_string(pg_blocking_pids(#{ddl_pid}), ',')) AS blocking_pids,
              (#{waiter_count_sql(ddl_pid, db_oid, "AND w.locktype = 'relation'")}) AS queued_waiters,
              (#{waiter_count_sql(ddl_pid, db_oid, '')}) AS unfiltered_waiters,
              (SELECT wait_event_type FROM pg_stat_activity
                WHERE pid = #{ddl_pid}
                  AND backend_start = #{quoted_backend_start}) AS ddl_wait_event_type
          SQL
        end

        def self.waiter_count_sql(ddl_pid, db_oid, locktype_filter)
          <<~SQL.squish
            SELECT count(DISTINCT w.pid) FROM pg_locks w
            WHERE NOT w.granted
              AND w.database = #{db_oid}
              AND w.pid <> #{ddl_pid}
              AND w.waitstart >= (
                SELECT min(o.waitstart) FROM pg_locks o
                WHERE o.pid = #{ddl_pid} AND NOT o.granted)
              #{locktype_filter}
              AND w.relation IN (
                SELECT d.relation FROM pg_locks d
                WHERE d.pid = #{ddl_pid}
                  AND d.database = #{db_oid}
                  AND d.relation IS NOT NULL)
          SQL
        end
        private_class_method :waiter_count_sql

        attr_reader :blocking_pids, :queued_waiters, :unfiltered_waiters, :wait_event_type

        def initialize(row)
          @blocking_pids = row['blocking_pids'].to_s.split(',').map { |pid| Integer(pid) }.sort.uniq
          @queued_waiters = row['queued_waiters'].to_i
          @unfiltered_waiters = row['unfiltered_waiters'].to_i
          @wait_event_type = row['ddl_wait_event_type'].to_s
        end

        def in_lock_wait?
          wait_event_type == 'Lock'
        end
      end
    end
  end
end
