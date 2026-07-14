# frozen_string_literal: true

class CreateDuoWorkflowsWorkflowPipelines < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  TABLE = :duo_workflows_workflow_pipelines

  # pipeline_id references p_ci_pipelines, which lives in the gitlab_ci database. A real
  # cross-database foreign key is not allowed, so integrity is maintained through a loose
  # foreign key (config/gitlab_loose_foreign_keys.yml) that deletes the link row when the
  # referenced pipeline is deleted.
  def up
    create_table TABLE, if_not_exists: true do |t|
      t.bigint :workflow_id, null: false
      t.bigint :pipeline_id, null: false
      t.bigint :project_id
      t.bigint :namespace_id
      t.timestamps_with_timezone null: false
      t.integer :link_type, limit: 2, null: false

      t.index [:workflow_id, :pipeline_id, :link_type], unique: true,
        name: 'index_duo_wf_wf_pipelines_on_workflow_id_and_pipeline_id'
      t.index :pipeline_id, name: 'index_duo_wf_wf_pipelines_on_pipeline_id'
      t.index :project_id, name: 'index_duo_wf_wf_pipelines_on_project_id'
      t.index :namespace_id, name: 'index_duo_wf_wf_pipelines_on_namespace_id'
    end

    add_multi_column_not_null_constraint TABLE, :project_id, :namespace_id
  end

  def down
    drop_table TABLE
  end
end
