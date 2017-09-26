class GenerateBoardFilters < ActiveRecord::Migration
  DOWNTIME = false

  def up
    # Sub-query executed on production
    # https://gitlab.com/gitlab-com/infrastructure/issues/2839#note_41023984
    execute <<-SQL
      INSERT INTO board_filters(board_id, milestone_id)
        SELECT id as board_id, milestone_id FROM boards
        WHERE (boards.milestone_id IS NOT NULL);
    SQL
  end

  def down
    execute <<-SQL
      DELETE FROM board_filters;
    SQL
  end
end
