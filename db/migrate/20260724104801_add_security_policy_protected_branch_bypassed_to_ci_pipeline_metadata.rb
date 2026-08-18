# frozen_string_literal: true

class AddSecurityPolicyProtectedBranchBypassedToCiPipelineMetadata < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :ci_pipeline_metadata, :security_policy_protected_branch_bypassed, :boolean,
      default: false, null: false
  end
end
