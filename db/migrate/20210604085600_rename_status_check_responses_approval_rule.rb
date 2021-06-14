# frozen_string_literal: true
class RenameStatusCheckResponsesApprovalRule < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    execute('DELETE FROM status_check_responses')

    unless column_exists?(:status_check_responses, :external_status_check_id)
      add_column :status_check_responses, :external_status_check_id, :bigint, null: false # rubocop:disable Rails/NotNullColumn
    end

    add_concurrent_foreign_key :status_check_responses, :external_status_checks, column: :external_status_check_id, on_delete: :cascade
    add_concurrent_foreign_key :status_check_responses, :merge_requests, column: :merge_request_id, on_delete: :cascade

    add_concurrent_index :status_check_responses, :external_status_check_id

    # Setting this to true so that we can remove the column in a future release once the column has been removed. It has been ignored in 14.0
    change_column_null :status_check_responses, :external_approval_rule_id, true

    with_lock_retries do
      remove_foreign_key :status_check_responses, :external_approval_rules
    end
  end

  def down
    change_column_null :status_check_responses, :external_approval_rule_id, false
    with_lock_retries do
      add_foreign_key :status_check_responses, :external_approval_rules
    end
    remove_column :status_check_responses, :external_status_check_id
  end
end
