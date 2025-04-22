# frozen_string_literal: true

class AllowNullNamespaceIdForProjectComplianceStandardsAdherence < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def change
    change_column_null :project_compliance_standards_adherence, :namespace_id, true
  end
end
