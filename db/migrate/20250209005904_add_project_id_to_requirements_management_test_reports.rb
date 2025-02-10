# frozen_string_literal: true

class AddProjectIdToRequirementsManagementTestReports < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :requirements_management_test_reports, :project_id, :bigint
  end
end
