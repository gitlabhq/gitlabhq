# frozen_string_literal: true

class AddForeignKeyToDastProfileSchedulesOnUser < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :dast_profile_schedules, :users, column: :user_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :dast_profile_schedules, column: :user_id
    end
  end
end
