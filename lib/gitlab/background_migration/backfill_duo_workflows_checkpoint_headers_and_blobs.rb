# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Copies legacy full-row checkpoints from p_duo_workflows_checkpoints into
    # p_duo_workflows_checkpoint_headers and p_duo_workflows_checkpoint_blobs,
    # so the legacy read path can be removed without losing rows written by
    # workflows that predate incremental checkpoints.
    #
    # Each legacy row becomes one header (the checkpoint minus channel_values)
    # plus one `compaction` blob per channel holding that channel's full value.
    # Rows that already have a header are skipped: dual-written rows, and a
    # re-sent thread_ts whose earlier row an earlier sub-batch already copied.
    # Readers then see the first migrated row's state for that thread_ts.
    class BackfillDuoWorkflowsCheckpointHeadersAndBlobs < BatchedMigrationJob # rubocop:disable Metrics/ClassLength -- one SQL query plus row mapping
      operation_name :backfill_duo_workflows_checkpoint_headers_and_blobs
      feature_category :duo_agent_platform
      cursor :id, :created_at

      tables_to_check_for_vacuum :p_duo_workflows_checkpoint_headers, :p_duo_workflows_checkpoint_blobs

      # Columns of idx_duo_wf_checkpoint_blobs_dedup, the conflict target for blobs.
      BLOBS_DEDUP_COLUMNS = %i[project_id workflow_id thread_ts channel version step_action workflow_created_at].freeze
      # Mirror the check constraints on the target tables.
      CHANNEL_KEYS_LIMIT = 100
      BLOB_DATA_LIMIT = 1_048_576
      # Mirrors the target tables' `retain_for`: an older workflow has no partition
      # left to hold its headers and blobs, so its legacy rows cannot be copied.
      RETENTION = 30.days

      def perform
        each_sub_batch do |sub_batch|
          rows = unmigrated_rows(sub_batch).select { |row| within_channel_cap?(row) }
          next if rows.empty?

          headers = rows.map { |row| header_attributes(row) }
          blobs = rows.flat_map { |row| blob_attributes(row) }

          headers_model = target_model(:p_duo_workflows_checkpoint_headers)
          blobs_model = target_model(:p_duo_workflows_checkpoint_blobs)

          headers_model.transaction do
            headers_model.insert_all(headers, returning: false)
            blobs_model.insert_all(blobs, unique_by: BLOBS_DEDUP_COLUMNS, returning: false) if blobs.any?
          end
        end
      end

      private

      # `candidates` is materialized so every NOT EXISTS clause references one
      # relation; the planner then prunes the header lookup to the workflow's
      # partition instead of probing all of them. The jsonb columns are read only
      # for rows that pass the filter. Ordered by id so that two rows of one
      # thread_ts in the same sub-batch get headers in legacy order.
      def unmigrated_rows(sub_batch)
        define_batchable_model(batch_table, connection: connection).find_by_sql(<<~SQL)
          WITH sub_batch AS MATERIALIZED (
            #{sub_batch.select(:id, :created_at).limit(sub_batch_size).to_sql}
          ),
          candidates AS MATERIALIZED (
            SELECT c.id, c.created_at, c.workflow_id, c.thread_ts, w.created_at AS workflow_created_at
            FROM sub_batch
            INNER JOIN p_duo_workflows_checkpoints c
              ON c.id = sub_batch.id AND c.created_at = sub_batch.created_at
            INNER JOIN duo_workflows_workflows w
              ON w.id = c.workflow_id
            WHERE w.created_at >= #{connection.quote(RETENTION.ago)}
          )
          SELECT
            c.id, c.workflow_id, c.project_id, c.namespace_id, c.thread_ts, c.parent_ts,
            c.checkpoint_ns, c.current_thread, c.checkpoint, c.metadata, c.created_at, c.updated_at,
            candidates.workflow_created_at
          FROM candidates
          INNER JOIN p_duo_workflows_checkpoints c
            ON c.id = candidates.id AND c.created_at = candidates.created_at
          WHERE NOT EXISTS (
            SELECT 1
            FROM p_duo_workflows_checkpoint_headers h
            WHERE h.workflow_id = candidates.workflow_id
              AND h.thread_ts = candidates.thread_ts
              AND h.workflow_created_at = candidates.workflow_created_at
          )
          ORDER BY c.id
        SQL
      end

      # The live write path rejects such a checkpoint with a 400. A header with a nil
      # membership would instead route the whole workflow to the legacy fallback.
      def within_channel_cap?(row)
        channels = channel_values_for(row).size
        return true if channels <= CHANNEL_KEYS_LIMIT

        log_skip('Skipped checkpoint with more channels than a header can record', row, channels: channels)
        false
      end

      def checkpoint_for(row)
        row.checkpoint.is_a?(Hash) ? row.checkpoint : {}
      end

      def channel_values_for(row)
        values = checkpoint_for(row)['channel_values']
        values.is_a?(Hash) ? values : {}
      end

      def header_attributes(row)
        shared_attributes(row).merge(
          parent_ts: row.parent_ts,
          checkpoint_ns: row.checkpoint_ns,
          checkpoint: checkpoint_for(row).except('channel_values'),
          metadata: row.metadata,
          channel_keys: channel_values_for(row).keys
        )
      end

      def blob_attributes(row)
        channel_values_for(row).filter_map do |channel, value|
          data = Zlib::Deflate.deflate(::Gitlab::Json.dump(value))
          if data.bytesize > BLOB_DATA_LIMIT
            next log_skip('Skipped checkpoint channel blob over the size limit', row, channel: channel,
              bytesize: data.bytesize)
          end

          shared_attributes(row).merge(
            channel: channel,
            # Readers only use version to dedup blobs of one thread_ts, so the legacy
            # row id makes a re-sent checkpoint's blobs distinct and a re-run a no-op.
            version: row.id.to_s,
            write_type: 'json',
            step_action: 'compaction',
            data: data
          )
        end
      end

      # Returns nil so callers can `next` or `select` the row away.
      def log_skip(message, row, **details)
        ::Gitlab::BackgroundMigration::Logger.warn(
          message: message, checkpoint_id: row.id, workflow_id: row.workflow_id, **details
        )
        nil
      end

      def shared_attributes(row)
        {
          workflow_id: row.workflow_id, project_id: row.project_id, namespace_id: row.namespace_id,
          workflow_created_at: row.workflow_created_at, thread_ts: row.thread_ts,
          current_thread: row.current_thread, created_at: row.created_at, updated_at: row.updated_at
        }
      end

      # define_batchable_model leaves primary_key nil on a composite-key table, and
      # insert_all then fails to resolve a conflict target for these two tables.
      def target_model(table)
        define_batchable_model(table, connection: connection, primary_key: [:id, :workflow_created_at])
      end
    end
  end
end
