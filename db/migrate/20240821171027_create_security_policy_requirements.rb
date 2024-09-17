# frozen_string_literal: true

class CreateSecurityPolicyRequirements < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    create_table :security_policy_requirements do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.bigint :compliance_framework_security_policy_id, null: false
      t.bigint :compliance_requirement_id, null: false
      t.bigint :namespace_id, null: false
      t.index :namespace_id
      t.index :compliance_requirement_id
      t.index [:compliance_framework_security_policy_id, :compliance_requirement_id], unique: true,
        name: :uniq_idx_security_policy_requirements_on_requirement_and_policy
    end
  end
end
