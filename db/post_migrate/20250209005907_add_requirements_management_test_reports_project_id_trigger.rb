# frozen_string_literal: true

class AddRequirementsManagementTestReportsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    install_sharding_key_assignment_trigger(
      table: :requirements_management_test_reports,
      sharding_key: :project_id,
      parent_table: :issues,
      parent_sharding_key: :project_id,
      foreign_key: :issue_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :requirements_management_test_reports,
      sharding_key: :project_id,
      parent_table: :issues,
      parent_sharding_key: :project_id,
      foreign_key: :issue_id
    )
  end
end
