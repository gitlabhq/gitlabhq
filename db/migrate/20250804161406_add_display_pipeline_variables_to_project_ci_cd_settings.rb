# frozen_string_literal: true

class AddDisplayPipelineVariablesToProjectCiCdSettings < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :project_ci_cd_settings, :display_pipeline_variables, :boolean, default: false, null: false
  end
end
