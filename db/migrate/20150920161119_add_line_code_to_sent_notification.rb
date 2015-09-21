class AddLineCodeToSentNotification < ActiveRecord::Migration
  def change
    add_column :sent_notifications, :line_code, :string
  end
end
