# rubocop:disable all
class RemoveAlertTypeFromBroadcastMessages < ActiveRecord::Migration[4.2]
  def change
    remove_column :broadcast_messages, :alert_type, :integer
  end
end
