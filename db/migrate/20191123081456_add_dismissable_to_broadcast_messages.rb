# frozen_string_literal: true

class AddDismissableToBroadcastMessages < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :broadcast_messages, :dismissable, :boolean
  end
end
