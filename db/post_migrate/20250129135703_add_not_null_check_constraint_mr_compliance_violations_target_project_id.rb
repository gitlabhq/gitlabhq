# frozen_string_literal: true

class AddNotNullCheckConstraintMrComplianceViolationsTargetProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    model = define_batchable_model(:merge_requests_compliance_violations, connection: connection)
    model.reset_column_information
    column = model.columns.find { |c| c.name == 'target_project_id' }

    change_column_null :merge_requests_compliance_violations, :target_project_id, true unless column.null

    add_not_null_constraint :merge_requests_compliance_violations, :target_project_id
  end

  def down
    remove_not_null_constraint :merge_requests_compliance_violations, :target_project_id
  end
end
