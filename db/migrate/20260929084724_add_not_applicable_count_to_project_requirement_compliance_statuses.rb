# frozen_string_literal: true

class AddNotApplicableCountToProjectRequirementComplianceStatuses < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :project_requirement_compliance_statuses, :not_applicable_count, :integer, default: 0, null: false
  end
end
