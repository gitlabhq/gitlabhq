# frozen_string_literal: true

class RepartitionPDuoWorkflowsCheckpointBlobsByWorkflowCreatedAt < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  disable_ddl_transaction!

  milestone '19.2'

  TABLE_NAME = :p_duo_workflows_checkpoint_blobs
  SEQ_NAME = :p_duo_workflows_checkpoint_blobs_id_seq
  FK_NAME = :fk_duo_wf_checkpoint_blobs_workflow_id
  DEDUP_INDEX = 'idx_duo_wf_checkpoint_blobs_dedup'
  WORKFLOW_ID_INDEX = 'index_duo_wf_checkpoint_blobs_on_workflow_id'
  NAMESPACE_ID_INDEX = 'index_duo_wf_checkpoint_blobs_on_namespace_id'
  DEDUP_COLUMNS = %i[project_id workflow_id thread_ts channel version step_action].freeze

  # The table has no data yet (incremental checkpoint blobs are not written on
  # any live path), so we drop and recreate it to change the partition key from
  # created_at to a dedicated workflow_created_at column. Every blob is written
  # with workflow_created_at = workflow.created_at, so all of a workflow's blobs
  # land in one daily partition and a lookup equality-prunes to it (avoiding the
  # LockManager LWLock contention of scanning every retained partition). Unlike
  # anchoring created_at, this keeps created_at/updated_at honest.
  # rubocop:disable Migration/DropTable -- Empty, unreferenced table (no live
  # writers); changing the partition key has no in-place ALTER, so we recreate it
  # in the same migration. No data loss, no downtime window in practice.
  def up
    drop_table TABLE_NAME

    create_partitioned
    finalize_table
  end

  def down
    drop_table TABLE_NAME

    create_partitioned_original
    finalize_table
  end
  # rubocop:enable Migration/DropTable

  private

  # Partitioned by a dedicated workflow_created_at column. Every blob is written
  # with workflow_created_at = workflow.created_at, so all of a workflow's blobs
  # land in one daily partition and a lookup equality-prunes to it.
  def create_partitioned
    create_table TABLE_NAME,
      primary_key: [:id, :workflow_created_at],
      options: 'PARTITION BY RANGE (workflow_created_at)',
      if_not_exists: true do |t|
      t.bigserial :id, null: false
      t.bigint :workflow_id, null: false
      t.bigint :project_id
      t.bigint :namespace_id
      t.datetime_with_timezone :workflow_created_at, null: false
      t.timestamps_with_timezone null: false
      t.integer :current_thread, null: false, default: 0
      t.text :thread_ts, null: false, limit: 255
      t.text :channel, null: false, limit: 255
      t.text :version, null: false, limit: 255
      t.text :write_type, null: false, limit: 255
      t.text :step_action, null: false, limit: 255
      t.binary :data, null: false

      t.index :workflow_id, name: WORKFLOW_ID_INDEX
      t.index :namespace_id, name: NAMESPACE_ID_INDEX
      # The partition key must be part of a partitioned table's unique index;
      # nulls_not_distinct covers the namespace-level (null project_id) branch of
      # the sharding key without a separate partial index.
      t.index DEDUP_COLUMNS + [:workflow_created_at],
        unique: true, nulls_not_distinct: true, name: DEDUP_INDEX
    end

    add_blob_check_constraints
  end

  # Reverses up: recreates the pre-repartition schema, partitioned by created_at
  # with no workflow_created_at column, so db/structure.sql matches master.
  def create_partitioned_original
    create_table TABLE_NAME,
      primary_key: [:id, :created_at],
      options: 'PARTITION BY RANGE (created_at)',
      if_not_exists: true do |t|
      t.bigserial :id, null: false
      t.bigint :workflow_id, null: false
      t.bigint :project_id
      t.bigint :namespace_id
      t.timestamps_with_timezone null: false
      t.integer :current_thread, null: false, default: 0
      t.text :thread_ts, null: false, limit: 255
      t.text :channel, null: false, limit: 255
      t.text :version, null: false, limit: 255
      t.text :write_type, null: false, limit: 255
      t.text :step_action, null: false, limit: 255
      t.binary :data, null: false

      t.index :workflow_id, name: WORKFLOW_ID_INDEX
      t.index :namespace_id, name: NAMESPACE_ID_INDEX
      t.index DEDUP_COLUMNS + [:created_at],
        unique: true, nulls_not_distinct: true, name: DEDUP_INDEX
    end

    add_blob_check_constraints
  end

  def add_blob_check_constraints
    add_check_constraint(
      TABLE_NAME,
      'num_nonnulls(namespace_id, project_id) = 1',
      'check_duo_wf_checkpoint_blobs_sharding_key'
    )

    add_check_constraint(
      TABLE_NAME,
      'octet_length(data) <= 1048576',
      'check_duo_wf_checkpoint_blobs_data_size'
    )
  end

  def finalize_table
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)

    add_concurrent_partitioned_foreign_key(
      TABLE_NAME,
      :duo_workflows_workflows,
      column: :workflow_id,
      name: FK_NAME,
      on_delete: :cascade
    )
  end
end
