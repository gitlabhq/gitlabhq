# frozen_string_literal: true

class AddCiPipelineVariablesMinimumRoleEnum < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :project_ci_cd_settings, :pipeline_variables_minimum_override_role,
      :integer, default: ProjectCiCdSetting::MAINTAINER_ROLE, null: false, limit: 2
  end
end
