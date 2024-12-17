# frozen_string_literal: true

class AddCreatedAtColumnToProjectComplianceFrameworkSettings < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :project_compliance_framework_settings, :created_at, :datetime_with_timezone
  end
end
