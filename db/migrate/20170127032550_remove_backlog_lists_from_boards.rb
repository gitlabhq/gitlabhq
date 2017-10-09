class RemoveBacklogListsFromBoards < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    execute <<-SQL
      DELETE FROM lists WHERE list_type = 0;
    SQL
  end

  def down
    execute <<-SQL
      INSERT INTO lists (board_id, list_type, created_at, updated_at)
      SELECT boards.id, 0, NOW(), NOW()
      FROM boards;
    SQL
  end
end
