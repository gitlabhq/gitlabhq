# frozen_string_literal: true

class AddThemeToBroadcastMessage < Gitlab::Database::Migration[1.0]
  def change
    add_column :broadcast_messages, :theme, :smallint, null: false, default: 0
  end
end
