class AddLineCodeToSentNotification < ActiveRecord::Migration[4.2]
  def change
    add_column :sent_notifications, :line_code, :string
  end
end
