# frozen_string_literal: true

class AddStateToMember < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    unless column_exists?(:members, :state)
      with_lock_retries do
        add_column :members, :state, :integer, limit: 2, default: 0
      end
    end
  end

  def down
    if column_exists?(:members, :state)
      with_lock_retries do
        remove_column :members, :state
      end
    end
  end
end
