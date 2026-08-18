# frozen_string_literal: true

class CreatePDuoWorkflowsCheckpointHeaders < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  # Range-partitioned by a dedicated workflow_created_at column (= the workflow's
  # created_at, set on every row) so all of a workflow's headers share one daily
  # partition and a lookup equality-prunes to it. The partition manager drops whole
  # day-partitions once they age past CHECKPOINT_RETENTION_DAYS (see
  # Ai::DuoWorkflows::CheckpointHeader#partitioned_by), so cleanup is a partition
  # DROP rather than a row-by-row DELETE. Mirrors p_duo_workflows_checkpoint_blobs.
  OPTIONS = {
    primary_key: [:id, :workflow_created_at],
    options: 'PARTITION BY RANGE (workflow_created_at)',
    if_not_exists: true
  }.freeze

  def up
    create_table :p_duo_workflows_checkpoint_headers, **OPTIONS do |t|
      t.bigserial :id, null: false
      t.bigint :workflow_id, null: false
      t.bigint :project_id
      t.bigint :namespace_id
      # Anchors every header to its workflow's daily partition; equal for all of a
      # workflow's headers, so a lookup prunes to a single partition.
      t.datetime_with_timezone :workflow_created_at, null: false
      t.timestamps_with_timezone null: false
      t.integer :current_thread, null: false, default: 0
      # Slim checkpoint header: the langgraph checkpoint minus channel_values
      # (channel_versions, versions_seen, v, ts, pending_sends). channel_values is
      # reconstructed from p_duo_workflows_checkpoint_blobs on read.
      t.jsonb :checkpoint, null: false
      t.jsonb :metadata, null: false
      t.text :thread_ts, null: false, limit: 255
      t.text :parent_ts, limit: 255

      # Append-only like p_duo_workflows_checkpoints: a re-sent checkpoint writes
      # another header row (readers take the latest), so there is no unique index. A
      # (workflow_id, thread_ts) read index is deferred to the reader change (#605653
      # step 3) so it lands with a query plan.
      t.index :workflow_id, name: 'index_duo_wf_checkpoint_headers_on_workflow_id'
      t.index :namespace_id, name: 'index_duo_wf_checkpoint_headers_on_namespace_id'
    end

    add_check_constraint(
      :p_duo_workflows_checkpoint_headers,
      'num_nonnulls(namespace_id, project_id) = 1',
      'check_duo_wf_checkpoint_headers_sharding_key'
    )
  end

  def down
    drop_table :p_duo_workflows_checkpoint_headers
  end
end
