# frozen_string_literal: true

class AddCiRunnerProjectsRunnerIdForeignKey < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_runner_projects, :ci_runners, column: :runner_id,
      on_delete: :cascade, validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key :ci_runner_projects, column: :runner_id
    end
  end
end
