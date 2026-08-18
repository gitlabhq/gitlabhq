# frozen_string_literal: true

module Gitlab
  module Database
    # Reports the Loose Foreign Keys (LFK) cleanup backlog per database connection and parent table.
    #
    # LooseForeignKeys::CleanupWorker drains loose_foreign_keys_deleted_records (and the sibling
    # sharding-key tables) every minute. When it cannot keep up - for example a high-fan-out parent
    # whose cleanup repeatedly hits statement timeouts - the pending backlog grows silently and can
    # eventually break migrations that assume the orphaned child rows were already cleaned up.
    #
    # This checker surfaces the backlog so it can be shown on /admin/database_diagnostics and alerted
    # on via Prometheus. See https://gitlab.com/gitlab-org/gitlab/-/issues/606252
    #
    # For every gitlab_shared connection (main, ci, sec) it returns, per parent table:
    #   - pending_records:           rows still awaiting cleanup (status = pending), capped at PENDING_RECORDS_LIMIT
    #   - capped:                    true when pending_records hit the cap (i.e. the real count is "N+")
    #   - oldest_pending_age_seconds: age of the oldest pending row (the fall-behind signal)
    #   - deferred_records:          rows rescheduled into the future (consume_after > now)
    #
    # The count/deferred aggregate is served entirely by the `status = pending` partial index
    # (partition, fully_qualified_table_name, consume_after, id) - i.e. an index-only scan that never
    # touches the heap - so it stays cheap even on a large backlog. The oldest age is read separately as
    # a single-row lookup per table (see #oldest_pending_at).
    class LooseForeignKeysBacklogChecker
      # Parent tables with fewer pending records than this are omitted from the results. A drop of
      # transient rows is expected and healthy; only accumulating tables are worth surfacing, and
      # this keeps both the admin output and the emitted metric cardinality bounded.
      MIN_PENDING_RECORDS = 1

      # Upper bound on the pending rows counted per store, so the count scan is always bounded (no
      # disabled statement timeout, which is a no-op behind PgBouncer anyway). A table with this many
      # pending records is already critically behind, so the exact magnitude past the cap is not useful
      # for alerting. We scan one extra row (PENDING_RECORDS_LIMIT + 1) so a table that reaches the cap
      # is reported with `capped: true` and a count clamped to PENDING_RECORDS_LIMIT (rendered "N+").
      #
      # Caveat: the cap is per query (per store), not per table, so in the rare case where several
      # tables together exceed the cap without any single one reaching it, the trailing tables are
      # under-counted without being flagged.
      PENDING_RECORDS_LIMIT = 10_000

      def self.run(logger: Gitlab::AppLogger)
        results = {}

        Gitlab::Database.database_base_models_with_gitlab_shared.each do |database_name, base_model|
          results[database_name] = new(base_model.connection, database_name, logger).run
        end

        results
      end

      attr_reader :connection, :database_name, :logger

      def initialize(connection, database_name, logger)
        @connection = connection
        @database_name = database_name
        @logger = logger
      end

      def run
        logger.info("Checking Loose Foreign Keys cleanup backlog on #{database_name} database...")

        backlog = aggregate_backlog

        logger.info("Found #{backlog.size} parent table(s) with a pending LFK cleanup backlog on #{database_name}.")

        backlog
      end

      private

      # The backlog for a single parent table can live in more than one store at once while the
      # DeletedRecordStore rollout is in progress (the cell-local table plus a sharding-key table), so
      # results are summed per parent table across every model on the connection.
      def aggregate_backlog
        aggregated = {}

        Gitlab::Database::SharedModel.using_connection(connection) do
          models.each { |model| collect_model_backlog(model, aggregated) }
        end

        finalize(aggregated)
      end

      # Reads one store's backlog into the accumulator. Both scans walk the `status = pending` partial
      # index, which can bloat with dead entries for already-processed records (LFK marks status = 2
      # rather than deleting), so on a cold, bloated index they can exceed the statement timeout. When
      # that happens, degrade gracefully - skip this store's contribution rather than failing the whole
      # diagnostic - and surface it via error tracking so the bloat/vacuum can be followed up.
      def collect_model_backlog(model, aggregated)
        capped_counts(model).each do |table_name, pending, deferred|
          entry = aggregated[table_name] ||= new_entry(table_name)

          entry['pending_records'] += pending.to_i
          entry['deferred_records'] += deferred.to_i

          oldest = oldest_pending_at(model, table_name)
          entry['oldest_pending_at'] = [entry['oldest_pending_at'], oldest].compact.min if oldest
        end
        # Degrade to a partial result instead of failing the whole diagnostic when the partial index is
        # bloated with dead entries; the fix is vacuum/backlog, not a different query.
      rescue ActiveRecord::QueryCanceled => e # rubocop:disable Database/RescueQueryCanceled -- see comment above
        track_slow_query(e, model)
      end

      def new_entry(table_name)
        {
          'parent_table' => table_name,
          'pending_records' => 0,
          'capped' => false,
          'oldest_pending_at' => nil,
          'deferred_records' => 0
        }
      end

      # Turns the internal accumulator into the reported shape: clamp the count to the cap (flagging
      # `capped`), convert the oldest timestamp into an age, drop tables below the reporting threshold,
      # and order oldest-first.
      def finalize(aggregated)
        now = Time.current

        aggregated.each_value do |entry|
          entry['capped'] = entry['pending_records'] > PENDING_RECORDS_LIMIT
          entry['pending_records'] = [entry['pending_records'], PENDING_RECORDS_LIMIT].min

          oldest = entry.delete('oldest_pending_at')
          entry['oldest_pending_age_seconds'] = oldest ? (now - oldest).round : 0
        end

        aggregated
          .values
          .select { |entry| entry['pending_records'] >= MIN_PENDING_RECORDS }
          .sort_by { |entry| -entry['oldest_pending_age_seconds'] }
      end

      # Counts pending rows (and the deferred subset) grouped by parent table, reading at most
      # PENDING_RECORDS_LIMIT + 1 rows in the partial-index order. Only index columns are selected
      # (fully_qualified_table_name, consume_after), so this is an index-only scan.
      def capped_counts(model)
        capped_pending = model
          .status_pending
          .select(:fully_qualified_table_name, :consume_after)
          .order(:partition, :fully_qualified_table_name, :consume_after, :id)
          .limit(PENDING_RECORDS_LIMIT + 1)

        model
          .unscoped
          .from(capped_pending, model.table_name)
          .group(:fully_qualified_table_name)
          .pluck(
            :fully_qualified_table_name,
            Arel.sql('COUNT(*)'),
            Arel.sql('COUNT(*) FILTER (WHERE consume_after > now())')
          )
      end

      # created_at of the record at the head of the cleanup queue for the table - the next one the
      # cleaner will process, and for a stalled queue the oldest. A single-row lookup in the partial
      # index order, so it reads one heap row rather than scanning the whole backlog for MIN(created_at).
      # Returns nil (age reported as unknown) if it times out on a bloated index rather than failing.
      def oldest_pending_at(model, table)
        model
          .status_pending
          .for_table(table)
          .order(:partition, :consume_after, :id)
          .pick(:created_at)
      rescue ActiveRecord::QueryCanceled => e # rubocop:disable Database/RescueQueryCanceled -- degrade to unknown age instead of failing; see #collect_model_backlog
        track_slow_query(e, model, table)
        nil
      end

      def track_slow_query(error, model, table = nil)
        Gitlab::ErrorTracking.track_exception(
          error,
          checker: self.class.name,
          database: database_name,
          store: model.table_name,
          parent_table: table
        )
      end

      def models
        ::Gitlab::LooseForeignKeys::DeletedRecordStore::MODELS
      end
    end
  end
end
