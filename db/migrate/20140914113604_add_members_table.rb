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

    add_index :members, :type
    add_index :members, :user_id
    add_index :members, :access_level
    add_index :members, [:source_id, :source_type]
  end
end
