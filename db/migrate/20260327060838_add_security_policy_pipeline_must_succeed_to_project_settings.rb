# frozen_string_literal: true

class AddSecurityPolicyPipelineMustSucceedToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :project_settings, :security_policy_pipeline_must_succeed, :boolean, default: false, null: false
  end
end
