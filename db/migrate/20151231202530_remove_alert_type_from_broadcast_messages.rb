class RemoveAlertTypeFromBroadcastMessages < ActiveRecord::Migration
  def change
    remove_column :broadcast_messages, :alert_type, :integer
  end
end
