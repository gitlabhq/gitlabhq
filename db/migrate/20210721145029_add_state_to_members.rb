# frozen_string_literal: true

class AddStateToMembers < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :members, :state, :integer, limit: 2, default: 0
    end
  end

  def down
    with_lock_retries do
      remove_column :members, :state
    end
  end
end
