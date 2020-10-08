# frozen_string_literal: true

class AddNotNullConstraintToComplianceProjectSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_not_null_constraint(:project_compliance_framework_settings, :framework_id)

    change_column_null(:compliance_management_frameworks, :namespace_id, false)
  end

  def down
    change_column_null(:compliance_management_frameworks, :namespace_id, true)

    remove_not_null_constraint(:project_compliance_framework_settings, :framework_id)
  end
end
