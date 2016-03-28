class CreateNotificationSettings < ActiveRecord::Migration
  def change
    create_table :notification_settings do |t|
      t.integer :user_id
      t.integer :level
      t.integer :source_id
      t.string :source_type

      t.timestamps null: false
    end
  end
end
