# frozen_string_literal: true

class AddForeignKeyToUserOnExperimentUsers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      # There is no need to use add_concurrent_foreign_key since it's an empty table
      add_foreign_key :experiment_users, :users, column: :user_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :experiment_users, column: :user_id
    end
  end
end
