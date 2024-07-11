# frozen_string_literal: true

class AddSeatControlToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :namespace_settings, :seat_control, :smallint, null: false, default: 0
  end
end
