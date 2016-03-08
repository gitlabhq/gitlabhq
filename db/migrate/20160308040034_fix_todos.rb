class FixTodos < ActiveRecord::Migration
  def up
    execute <<-SQL
      DELETE FROM todos
      WHERE NOT EXISTS (
        SELECT *
        FROM projects
        WHERE projects.id = todos.id
      )
    SQL
  end

  def down
  end
end
