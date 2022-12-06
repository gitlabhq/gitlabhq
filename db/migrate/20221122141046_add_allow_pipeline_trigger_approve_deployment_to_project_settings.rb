# frozen_string_literal: true

class AddAllowPipelineTriggerApproveDeploymentToProjectSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :project_settings, :allow_pipeline_trigger_approve_deployment, :boolean, default: false, null: false
  end
end
