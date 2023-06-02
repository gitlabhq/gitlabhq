# frozen_string_literal: true

class AddShowInCliToBroadcastMessage < Gitlab::Database::Migration[2.1]
  def change
    add_column :broadcast_messages, :show_in_cli, :boolean, default: true, null: false
  end
end
