# frozen_string_literal: true

class CreatePDuoWorkflowsCheckpoints < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '18.2'
  disable_ddl_transaction!

  OPTIONS = {
    primary_key: [:id, :created_at],
    options: 'PARTITION BY RANGE (created_at)',
    if_not_exists: true
  }

  def up
    create_table :p_duo_workflows_checkpoints, **OPTIONS do |t| # rubocop:disable Migration/EnsureFactoryForTable -- see ee/spec/factories/ai/duo_workflows/workflow_checkpoints.rb
      t.bigserial :id, null: false
      t.bigint :workflow_id, null: false
      t.bigint :project_id, index: true
      t.timestamps_with_timezone null: false
      t.bigint :namespace_id, index: true
      t.text :thread_ts, null: false, limit: 255
      t.text :parent_ts, null: true, limit: 255
      t.jsonb :checkpoint, null: false
      t.jsonb :metadata, null: false

      t.index [:workflow_id, :thread_ts],
        name: 'index_p_duo_workflows_checkpoints_thread'
    end

    add_multi_column_not_null_constraint(:p_duo_workflows_checkpoints, :project_id, :namespace_id)

    add_concurrent_partitioned_foreign_key :p_duo_workflows_checkpoints, :namespaces, validate: true,
      column: :namespace_id, on_delete: :cascade
    add_concurrent_partitioned_foreign_key :p_duo_workflows_checkpoints, :projects, validate: true,
      column: :project_id, on_delete: :cascade
    add_concurrent_partitioned_foreign_key :p_duo_workflows_checkpoints, :duo_workflows_workflows, validate: true,
      column: :workflow_id, on_delete: :cascade
  end

  def down
    drop_table :p_duo_workflows_checkpoints
  end
end
