# frozen_string_literal: true

class AddTargetAccessLevelsToBroadcastMessages < Gitlab::Database::Migration[1.0]
  def up
    add_column :broadcast_messages, :target_access_levels, :integer, if_not_exists: true, array: true, null: false, default: []
  end

  def down
    remove_column :broadcast_messages, :target_access_levels, if_exists: true
  end
end
