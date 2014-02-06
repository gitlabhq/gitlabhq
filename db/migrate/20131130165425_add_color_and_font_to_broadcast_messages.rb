class AddColorAndFontToBroadcastMessages < ActiveRecord::Migration
  def change
    add_column :broadcast_messages, :color, :string
    add_column :broadcast_messages, :font, :string
  end
end
