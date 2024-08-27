# frozen_string_literal: true

class AddProjectForeignKeyToProjectSavedReplies < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.3'

  def up
    add_concurrent_foreign_key :project_saved_replies, :projects, column: :project_id, on_delete: :cascade,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key :project_saved_replies, column: :project_id
    end
  end
end
