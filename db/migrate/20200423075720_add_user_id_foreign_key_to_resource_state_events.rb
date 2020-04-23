# frozen_string_literal: true

class AddUserIdForeignKeyToResourceStateEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :resource_state_events, :users, column: :user_id, on_delete: :nullify # rubocop:disable Migration/AddConcurrentForeignKey
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :resource_state_events, column: :user_id
    end
  end
end
