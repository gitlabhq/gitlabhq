class AddEmailToBroadcastMessages < ActiveRecord::Migration
  def change
    add_column :broadcast_messages, :email, :boolean
  end
end
