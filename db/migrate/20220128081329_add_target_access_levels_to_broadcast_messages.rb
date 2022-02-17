# frozen_string_literal: true

class AddTargetAccessLevelsToBroadcastMessages < Gitlab::Database::Migration[1.0]
  def change
    add_column :broadcast_messages, :target_access_levels, :integer, array: true, null: false, default: []
  end
end
