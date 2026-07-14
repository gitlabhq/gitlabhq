# frozen_string_literal: true

class AddSkipBranchPipelinesForMrsToProjectCiCdSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :project_ci_cd_settings, :skip_branch_pipelines_for_mrs, :boolean, default: false, null: false
  end
end
