# frozen_string_literal: true

class AddComplianceFrameworkIdToNamespaceSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :namespace_settings, :default_compliance_framework_id, :bigint
  end
end
