# frozen_string_literal: true

class CreatePDuoWorkflowsCheckpointBlobs < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  # Range-partitioned by created_at to align physical storage with the 30-day TTL:
  # the partition manager drops whole day-partitions once they age past
  # CHECKPOINT_RETENTION_DAYS (see Ai::DuoWorkflows::CheckpointBlob#partitioned_by),
  # so cleanup is a partition DROP rather than a row-by-row DELETE. Mirrors the
  # sibling p_duo_workflows_checkpoints table.
  OPTIONS = {
    primary_key: [:id, :created_at],
    options: 'PARTITION BY RANGE (created_at)',
    if_not_exists: true
  }.freeze

  def up
    create_table :p_duo_workflows_checkpoint_blobs, **OPTIONS do |t|
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
      # Raw (base64-decoded) blob bytes for incremental checkpointing. Stored as
      # bytea rather than base64 text to drop the ~33% encoding overhead; size is
      # bounded by the check constraint below. Transient (30-day TTL).
      t.binary :data, null: false

      t.index :workflow_id, name: 'index_duo_wf_checkpoint_blobs_on_workflow_id'
      t.index :namespace_id, name: 'index_duo_wf_checkpoint_blobs_on_namespace_id'
      # created_at is part of the unique key because a partitioned table's unique
      # index must include the partition key. nulls_not_distinct treats NULL
      # project_id rows (namespace-level workflows) as equal, so the unique
      # constraint also covers the namespace branch of the sharding key without
      # needing a separate partial index.
      t.index [:project_id, :workflow_id, :thread_ts, :channel, :version, :created_at],
        unique: true, nulls_not_distinct: true, name: 'idx_duo_wf_checkpoint_blobs_unique'
    end

    add_check_constraint(
      :p_duo_workflows_checkpoint_blobs,
      'num_nonnulls(namespace_id, project_id) = 1',
      'check_duo_wf_checkpoint_blobs_sharding_key'
    )

    add_check_constraint(
      :p_duo_workflows_checkpoint_blobs,
      'octet_length(data) <= 1048576',
      'check_duo_wf_checkpoint_blobs_data_size'
    )
  end

  def down
    drop_table :p_duo_workflows_checkpoint_blobs
  end
end
