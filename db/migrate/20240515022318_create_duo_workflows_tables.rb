# frozen_string_literal: true

class CreateDuoWorkflowsTables < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    create_table :duo_workflows_workflows do |t| # rubocop:disable Migration/EnsureFactoryForTable, Lint/RedundantCopDisableDirective -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.bigint :user_id, null: false, index: true
      t.bigint :project_id, null: false, index: true

      t.timestamps_with_timezone null: false
    end

    create_table :duo_workflows_checkpoints do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.references :workflow, foreign_key: { to_table: :duo_workflows_workflows, on_delete: :cascade }, null: false,
        index: false
      t.bigint :project_id, null: false, index: true
      t.timestamps_with_timezone null: false
      t.text :thread_ts, null: false, limit: 255
      t.text :parent_ts, null: true, limit: 255
      t.jsonb :checkpoint, null: false
      t.jsonb :metadata, null: false

      t.index [:workflow_id, :thread_ts], unique: true, name: 'index_duo_workflows_workflow_checkpoints_unique_thread'
    end
  end
end
