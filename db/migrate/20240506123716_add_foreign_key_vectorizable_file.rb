# frozen_string_literal: true

class AddForeignKeyVectorizableFile < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ai_agent_version_attachments, :ai_vectorizable_files, column: :ai_vectorizable_file_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :ai_agent_version_attachments, column: :ai_vectorizable_file_id
    end
  end
end
