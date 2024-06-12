# frozen_string_literal: true

class AddStatusCheckResponsesProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :status_check_responses, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :status_check_responses, column: :project_id
    end
  end
end
