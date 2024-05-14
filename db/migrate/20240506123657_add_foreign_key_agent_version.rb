# frozen_string_literal: true

class AddForeignKeyAgentVersion < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ai_agent_version_attachments, :ai_agent_versions, column: :ai_agent_version_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :ai_agent_version_attachments, column: :ai_agent_version_id
    end
  end
end
