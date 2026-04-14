# frozen_string_literal: true

class CreateDuoWorkflowSessionArtifacts < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.11'

  def up
    create_table :duo_workflow_session_artifacts, if_not_exists: true do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.timestamps_with_timezone null: false
      t.references :workflow, null: false, index: false
      t.references :project, null: true, index: false
      t.references :namespace, null: true, index: false
      t.bigint :user_id, null: false
      t.integer :status, limit: 2, default: 0, null: false
      t.text :workflow_definition, default: 'software_development', null: false, limit: 255
      t.float :credits_used, default: 0, null: false
      t.text :model_used, default: '', null: false, limit: 255
      t.datetime_with_timezone :workflow_created_at, null: false
      t.datetime_with_timezone :workflow_updated_at, null: false

      t.index :workflow_id, unique: true, name: 'index_duo_wf_session_artifacts_on_workflow_id'
      t.index :user_id, name: 'index_duo_wf_session_artifacts_on_user_id'
      t.index [:namespace_id, :workflow_updated_at],
        order: { workflow_updated_at: :desc },
        name: 'index_duo_wf_session_artifacts_on_namespace_id_updated_at'
      t.index [:project_id, :workflow_updated_at],
        order: { workflow_updated_at: :desc },
        name: 'index_duo_wf_session_artifacts_on_project_id_updated_at'
    end

    add_concurrent_foreign_key :duo_workflow_session_artifacts, :duo_workflows_workflows,
      column: :workflow_id, on_delete: :cascade
    add_concurrent_foreign_key :duo_workflow_session_artifacts, :projects,
      column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :duo_workflow_session_artifacts, :namespaces,
      column: :namespace_id, on_delete: :cascade
    add_concurrent_foreign_key :duo_workflow_session_artifacts, :users,
      column: :user_id, on_delete: :cascade

    add_multi_column_not_null_constraint :duo_workflow_session_artifacts, :project_id, :namespace_id
  end

  def down
    drop_table :duo_workflow_session_artifacts
  end
end
