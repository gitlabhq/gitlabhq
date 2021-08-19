# frozen_string_literal: true

class RemoveForeignKeysFromCiTestCases < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  TABLE_NAME = :ci_test_cases

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(TABLE_NAME, column: :project_id)
    end
  end

  def down
    add_concurrent_foreign_key(TABLE_NAME, :projects, column: :project_id, on_delete: :cascade)
  end
end
