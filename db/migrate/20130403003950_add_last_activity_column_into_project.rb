class AddLastActivityColumnIntoProject < ActiveRecord::Migration
  def up
    add_column :projects, :last_activity_at, :datetime
    add_index :projects, :last_activity_at

    select_all('SELECT id, updated_at FROM projects').each do |project|
      project_id = project['id']
      update_date = project['updated_at']
      event = select_one("SELECT created_at FROM events WHERE project_id = #{project_id} ORDER BY created_at DESC LIMIT 1")

      if event && event['created_at']
        update_date = event['created_at']
      end

      execute("UPDATE projects SET last_activity_at = '#{update_date}' WHERE id = #{project_id}")
    end
  end

  def down
    remove_index :projects, :last_activity_at
    remove_column :projects, :last_activity_at
  end
end
