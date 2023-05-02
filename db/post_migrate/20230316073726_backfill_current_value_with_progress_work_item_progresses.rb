# frozen_string_literal: true

class BackfillCurrentValueWithProgressWorkItemProgresses < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    each_batch('work_item_progresses', connection: connection) do |relation|
      min, max = relation.pick('MIN(issue_id), MAX(issue_id)')

      execute(<<~SQL)
        UPDATE work_item_progresses SET current_value = progress
        WHERE issue_id BETWEEN #{min} AND #{max}
      SQL
    end
  end

  def down
    # no-op as the columns are newly added
  end
end
