# frozen_string_literal: true

class AddUsersFkToResourceIterationEventsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :resource_iteration_events, :users, column: :user_id, on_delete: :nullify
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :resource_iteration_events, column: :user_id
    end
  end
end
