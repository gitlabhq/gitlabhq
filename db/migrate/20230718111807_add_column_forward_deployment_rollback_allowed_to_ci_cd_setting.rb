# frozen_string_literal: true

class AddColumnForwardDeploymentRollbackAllowedToCiCdSetting < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column :project_ci_cd_settings, :forward_deployment_rollback_allowed, :boolean, default: true, null: false
  end

  def down
    remove_column :project_ci_cd_settings, :forward_deployment_rollback_allowed
  end
end
