# frozen_string_literal: true

class MakeTargetProjectIdNotNullOnComplianceViolations < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    change_column_null :merge_requests_compliance_violations, :target_project_id, false
  end
end
