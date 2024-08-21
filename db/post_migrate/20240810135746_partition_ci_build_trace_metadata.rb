# frozen_string_literal: true

class PartitionCiBuildTraceMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  # rubocop:disable Migration/SchemaAdditionMethodsNoPost -- recreates the table in the same transaction
  def up
    with_lock_retries do
      lock_tables(:p_ci_builds, :p_ci_job_artifacts, :ci_build_trace_metadata, mode: :access_exclusive)

      drop_table(:ci_build_trace_metadata)

      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS ci_build_trace_metadata
          PARTITION OF p_ci_build_trace_metadata
          FOR VALUES IN (100, 101, 102);
      SQL
    end
  end

  def down
    drop_table(:ci_build_trace_metadata, if_exists: true)

    create_table(:ci_build_trace_metadata, id: false, if_not_exists: true) do |t|
      t.bigint :build_id, null: false, default: nil, primary_key: true
      t.bigint :trace_artifact_id
      t.integer :archival_attempts, default: 0, null: false, limit: 2
      t.binary :checksum
      t.binary :remote_checksum
      t.datetime_with_timezone :last_archival_attempt_at
      t.datetime_with_timezone :archived_at
      t.bigint :partition_id, null: false

      t.index [:trace_artifact_id, :partition_id],
        name: :index_ci_build_trace_metadata_on_trace_artifact_id_partition_id
      t.index [:partition_id, :build_id], unique: true,
        name: :index_ci_build_trace_metadata_on_partition_id_build_id
    end

    add_concurrent_foreign_key(
      :ci_build_trace_metadata, :p_ci_builds,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true,
      name: :fk_rails_aebc78111f_p
    )

    add_concurrent_foreign_key(
      :ci_build_trace_metadata, :p_ci_job_artifacts,
      column: [:partition_id, :trace_artifact_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true,
      name: :fk_21d25cac1a_p
    )
  end
  # rubocop:enable Migration/SchemaAdditionMethodsNoPost
end
