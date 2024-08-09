# frozen_string_literal: true

class AddProjectIdToComplianceFrameworkSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :compliance_framework_security_policies, :project_id, :bigint
  end
end
