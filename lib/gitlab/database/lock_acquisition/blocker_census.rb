# frozen_string_literal: true

module Gitlab
  module Database
    module LockAcquisition
      # Captures the sessions holding locks on the given tables after a lock
      # acquisition attempt failed, so the failure names its blockers
      # instead of only its timeout. Read-only and rescue-guarded:
      # observability must never fail the caller.
      #
      # Interpretation caveats for consumers of this data:
      # - This runs after we left the lock queue, so fast queue-jumping
      #   traffic that starved the attempt has already committed. An empty
      #   census means "no long-lived holder", not "nothing blocked us".
      # - pg_stat_activity hides state/query/backend_type for other roles'
      #   backends (superuser sessions, autovacuum workers) unless the
      #   census role has pg_monitor. Hidden rows still appear via pg_locks
      #   (pid and lock modes, null stats), are counted in
      #   privilege_restricted_count, and yield a null wraparound_vacuum
      #   flag rather than a false one.
      # - Blockers holding locks only on partitions of a target table are
      #   not matched by the parent table's name.
      # - application/endpoint_id are only populated in production:
      #   Marginalia comments are PREPENDED there
      #   (config/initializers/query_logs.rb, so they survive
      #   pg_stat_activity's 1024-byte truncation) but appended in dev/test.
      #   Do not "fix" the anchor to trailing position based on local data.
      class BlockerCensus
        MAX_BLOCKERS = 20

        HIDDEN_QUERY = '<insufficient privilege>'

        # Same anchored extraction as Gitlab::Database::StatActivitySampler:
        # both capture groups have bounded character classes, so no free
        # text from another session's SQL can pass through.
        MARGINALIA_PATTERN = '^\\s*(?:/\\*(?:application:(\\w+),?)?(?:correlation_id:[\\w\\-]+,?)?' \
          '(?:jid:\\w+,?)?(?:endpoint_id:([\\w/\\-\\.:#\\s]+),?)?.*?\\*/)?'

        def self.capture(connection, tables:)
          new(connection, tables: tables).capture
        end

        def initialize(connection, tables:)
          @connection = connection
          @tables = Array(tables).map(&:to_s)
        end

        # @return [Hash] loggable payload; never raises
        def capture
          # pg_stat_activity freezes at a transaction's first read, hiding
          # blockers that connected since; transactional migrations read it
          # long before we run, so discard that snapshot (a no-op outside
          # a transaction). ::text because AR cannot type-cast void.
          connection.select_value('SELECT pg_stat_clear_snapshot()::text')

          {
            blockers: connection.select_all(census_sql).to_a,
            privilege_restricted_count: scalar(
              "SELECT count(DISTINCT l.pid) #{blocker_locks_sql} AND a.query = #{connection.quote(HIDDEN_QUERY)}"
            )
          }
        rescue StandardError => e
          { census_error: "#{e.class}: #{e.message}".truncate(200) }
        end

        private

        attr_reader :connection, :tables

        def scalar(sql)
          connection.select_value(sql).to_i
        end

        # Sessions holding a granted lock on any of the target relations.
        # Grouped per session (one session can hold several lock modes) and
        # ordered oldest transaction first: those are the ones a bounded
        # retry cannot outwait. pg_locks rows from other databases in the
        # cluster are excluded because relation OIDs are only unique per
        # database. to_regclass resolves names via search_path, avoiding
        # accidental matches on same-named relations in other schemas.
        def census_sql
          <<~SQL
            SELECT #{blocker_columns}, array_agg(DISTINCT l.mode) AS lock_modes
            #{blocker_locks_sql}
            GROUP BY #{grouping_columns}
            ORDER BY a.xact_start ASC NULLS LAST
            LIMIT #{MAX_BLOCKERS}
          SQL
        end

        def blocker_locks_sql
          <<~SQL
            FROM pg_locks l
            JOIN pg_stat_activity a ON a.pid = l.pid
            WHERE l.granted
              AND l.database = (SELECT oid FROM pg_database WHERE datname = current_database())
              AND l.relation IN (SELECT to_regclass(t)::oid FROM unnest(ARRAY[#{quoted_table_names}]::text[]) AS t)
              AND l.pid <> pg_backend_pid()
          SQL
        end

        # Never the statement body: another session's SQL can contain
        # literals (tokens, emails) and Rails logs are more widely
        # accessible than PG server logs. Only the named Marginalia fields
        # are extracted, via MARGINALIA_PATTERN.
        def blocker_columns
          <<~SQL.squish
            a.pid,
            a.backend_type,
            a.state,
            round(extract(epoch FROM clock_timestamp() - a.xact_start)::numeric, 3)::float AS xact_age_s,
            round(extract(epoch FROM clock_timestamp() - a.query_start)::numeric, 3)::float AS query_age_s,
            a.application_name,
            a.wait_event_type,
            CASE WHEN a.query IS NULL OR a.query = #{connection.quote(HIDDEN_QUERY)} THEN NULL
                 ELSE a.backend_type = 'autovacuum worker' AND a.query LIKE '%to prevent wraparound%'
            END AS wraparound_vacuum,
            (regexp_match(a.query, '#{MARGINALIA_PATTERN}'))[1] AS application,
            (regexp_match(a.query, '#{MARGINALIA_PATTERN}'))[2] AS endpoint_id
          SQL
        end

        def grouping_columns
          'a.pid, a.backend_type, a.state, a.xact_start, a.query_start, ' \
            'a.application_name, a.wait_event_type, a.query'
        end

        def quoted_table_names
          tables.map { |table| connection.quote(table) }.join(', ')
        end
      end
    end
  end
end
