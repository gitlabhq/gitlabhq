# frozen_string_literal: true

class AddSecurityPolicyProtectedBranchBypassedToSiphonCiPipelineMetadata < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_ci_pipeline_metadata ADD COLUMN IF NOT EXISTS security_policy_protected_branch_bypassed Bool DEFAULT false CODEC(ZSTD(1))
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_ci_pipeline_metadata DROP COLUMN IF EXISTS security_policy_protected_branch_bypassed
    SQL
  end
end
