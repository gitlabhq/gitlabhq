# rubocop:disable all
class AddColorAndFontToBroadcastMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :broadcast_messages, :color, :string
    add_column :broadcast_messages, :font, :string
  end
end
