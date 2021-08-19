# frozen_string_literal: true

class AddForeignKeyToDastProfileSchedulesOnDastProfile < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :dast_profile_schedules, :dast_profiles, column: :dast_profile_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :dast_profile_schedules, column: :dast_profile_id
    end
  end
end
