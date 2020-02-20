# frozen_string_literal: true

class AddRestrictDeploymentOrderToProjectCiCdSettings < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :project_ci_cd_settings, :forward_deployment_enabled, :boolean
  end
end
