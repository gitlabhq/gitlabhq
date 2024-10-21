# frozen_string_literal: true

module Gitlab
  module Database
    module HealthStatus
      module Indicators
        class WriteAheadLog
          include Gitlab::Utils::StrongMemoize

          LIMIT = 42
          PENDING_WAL_COUNT_SQL = <<~SQL
            WITH
            current_wal_file AS (
              SELECT pg_walfile_name(pg_current_wal_insert_lsn()) AS pg_walfile_name
            ),
            current_wal AS (
              SELECT
                ('x' || substring(pg_walfile_name, 9, 8))::bit(32)::int AS log,
                ('x' || substring(pg_walfile_name, 17, 8))::bit(32)::int AS seg,
                pg_walfile_name
              FROM current_wal_file
            ),
            archive_wal AS (
              SELECT
                ('x' || substring(last_archived_wal, 9, 8))::bit(32)::int AS log,
                ('x' || substring(last_archived_wal, 17, 8))::bit(32)::int AS seg,
                last_archived_wal
              FROM pg_stat_archiver
            )
            SELECT ((current_wal.log - archive_wal.log) * 256) + (current_wal.seg - archive_wal.seg) AS pending_wal_count
            FROM current_wal, archive_wal
          SQL

          def initialize(context)
            @connection = context.connection
          end

          def evaluate
            return Signals::NotAvailable.new(self.class, reason: 'indicator disabled') unless enabled?

            unless pending_wal_count
              return Signals::NotAvailable.new(self.class, reason: 'WAL archive queue can not be calculated')
            end

            if pending_wal_count > LIMIT
              Signals::Stop.new(self.class, reason: "WAL archive queue is too big")
            else
              Signals::Normal.new(self.class, reason: 'WAL archive queue is within limit')
            end
          end

          private

          attr_reader :connection

          def enabled?
            Feature.enabled?(:batched_migrations_health_status_wal, type: :ops)
          end

          # Returns number of WAL segments pending archival
          def pending_wal_count
            Gitlab::Database::LoadBalancing::SessionMap.current(connection.load_balancer).use_primary do
              connection.execute(PENDING_WAL_COUNT_SQL).to_a.first&.fetch('pending_wal_count')
            end
          end
          strong_memoize_attr :pending_wal_count
        end
      end
    end
  end
end
