# frozen_string_literal: true

class RemoveForeignKeysFromCiTestCaseFailures < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  TABLE_NAME = :ci_test_case_failures

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(TABLE_NAME, column: :build_id)
    end

    with_lock_retries do
      remove_foreign_key_if_exists(TABLE_NAME, column: :test_case_id)
    end
  end

  def down
    add_concurrent_foreign_key(TABLE_NAME, :ci_builds, column: :build_id, on_delete: :cascade)
    add_concurrent_foreign_key(TABLE_NAME, :ci_test_cases, column: :test_case_id, on_delete: :cascade)
  end
end
