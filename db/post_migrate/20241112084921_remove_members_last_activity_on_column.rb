# frozen_string_literal: true

class RemoveMembersLastActivityOnColumn < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    remove_column :members, :last_activity_on
  end

  def down
    return if column_exists?(:members, :last_activity_on)

    add_column :members, :last_activity_on, :date, default: -> { 'NOW()' }
  end
end
