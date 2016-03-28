class CreateNotificationSettings < ActiveRecord::Migration
  def change
    create_table :notification_settings do |t|
      t.references :user, null: false
      t.references :source, polymorphic: true, null: false
      t.integer :level, default: 0, null: false

      t.timestamps null: false
    end
  end
end
