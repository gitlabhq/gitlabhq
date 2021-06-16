# frozen_string_literal: true

class AddRequirementTestReportsForeignKey < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TARGET_TABLE = :requirements_management_test_reports
  CONSTRAINT_NAME = 'requirements_test_reports_requirement_id_xor_issue_id'

  def up
    add_concurrent_foreign_key TARGET_TABLE, :issues, column: :issue_id

    add_check_constraint(TARGET_TABLE, 'num_nonnulls(requirement_id, issue_id) = 1', CONSTRAINT_NAME)
  end

  def down
    remove_check_constraint TARGET_TABLE, CONSTRAINT_NAME

    with_lock_retries do
      remove_foreign_key_if_exists(TARGET_TABLE, column: :issue_id)
    end
  end
end
