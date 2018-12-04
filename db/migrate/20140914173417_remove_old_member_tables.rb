# rubocop:disable all
class RemoveOldMemberTables < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    drop_table :users_groups
    drop_table :users_projects
  end

  def down
    create_table :users_groups do |t|
      t.integer :group_access, null: false
      t.integer :group_id, null: false
      t.integer :user_id, null: false
      t.integer :notification_level, null: false, default: 3

      t.timestamps null: true
    end

    create_table :users_projects do |t|
      t.integer :project_access, null: false
      t.integer :project_id, null: false
      t.integer :user_id, null: false
      t.integer :notification_level, null: false, default: 3

      t.timestamps null: true
    end
  end
end
