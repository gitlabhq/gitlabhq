# frozen_string_literal: true

class AddPipelineCancelRoleRestrictionEnum < Gitlab::Database::Migration[2.1]
  def up
    add_column :project_ci_cd_settings, :restrict_pipeline_cancellation_role,
      :integer, limit: 2, default: 0, null: false
  end

  def down
    remove_column :project_ci_cd_settings, :restrict_pipeline_cancellation_role
  end
end
