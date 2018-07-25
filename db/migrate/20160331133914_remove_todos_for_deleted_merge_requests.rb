class RemoveTodosForDeletedMergeRequests < ActiveRecord::Migration
  def up
    execute <<-SQL
      DELETE FROM todos
      WHERE todos.target_type = 'MergeRequest'
        AND NOT EXISTS (
              SELECT *
              FROM merge_requests
              WHERE merge_requests.id = todos.target_id
                AND merge_requests.deleted_at IS NULL
            )
    SQL
  end

  def down
  end
end
