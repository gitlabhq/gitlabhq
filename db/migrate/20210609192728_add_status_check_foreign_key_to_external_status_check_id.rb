# frozen_string_literal: true

class AddStatusCheckForeignKeyToExternalStatusCheckId < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :external_status_checks_protected_branches, :external_status_checks, column: :external_status_check_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :external_status_checks_protected_branches, column: :external_status_check_id
    end
  end
end
