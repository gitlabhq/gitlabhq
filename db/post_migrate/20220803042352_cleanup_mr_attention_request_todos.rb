# frozen_string_literal: true

class CleanupMrAttentionRequestTodos < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class Todo < MigrationRecord
    self.table_name = 'todos'

    include ::EachBatch

    ATTENTION_REQUESTED = 10
  end

  def up
    Todo.where(action: Todo::ATTENTION_REQUESTED).each_batch do |todos_batch|
      todos_batch.delete_all
    end
  end

  def down
    # Attention request feature has been reverted.
  end
end
