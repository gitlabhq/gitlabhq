# frozen_string_literal: true

class AddAllowRunPipelinesInTheParentProjectSetting < Gitlab::Database::Migration[2.0]
  def change
    add_column :project_ci_cd_settings, :allow_fork_pipelines_to_run_in_parent_project, :boolean,
      default: true, null: false
  end
end
