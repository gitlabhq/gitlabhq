class AddMembersTable < ActiveRecord::Migration
  def change
    create_table :members do |t|
      t.integer :access_level, null: false
      t.integer :source_id,    null: false
      t.string  :source_type,  null: false
      t.integer :user_id,      null: false
      t.integer :notification_level, null: false
      t.string  :type

      t.timestamps
    end
  end
end
