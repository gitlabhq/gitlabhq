class AddSentNotifications < ActiveRecord::Migration
  def change
    create_table :sent_notifications do |t|
      t.references :project
      t.references :noteable, polymorphic: true
      t.references :recipient
      t.string :commit_id
      t.string :reply_key, null: false
    end

    add_index :sent_notifications, :reply_key, unique: true
  end
end
