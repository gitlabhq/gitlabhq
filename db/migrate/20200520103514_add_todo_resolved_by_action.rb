# frozen_string_literal: true

class AddTodoResolvedByAction < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :todos, :resolved_by_action, :integer, limit: 2
    end
  end

  def down
    with_lock_retries do
      remove_column :todos, :resolved_by_action
    end
  end
end
