# frozen_string_literal: true

class AddTargetPathToBroadcastMessage < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :broadcast_messages, :target_path, :string, limit: 255
  end
end
