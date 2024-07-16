# frozen_string_literal: true

class CreateDuoWorkflowsUserForeignKey < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :duo_workflows_workflows,
      :users,
      column: :user_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :duo_workflows_workflows, column: :user_id
    end
  end
end
