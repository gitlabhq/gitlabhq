# frozen_string_literal: true

class RemoveCiPipelineChatDataFkOnChatNames < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_pipeline_chat_data, :chat_names, name: "fk_rails_f300456b63")
    end
  end

  def down
    # Remove orphaned rows
    execute <<~SQL
    DELETE FROM ci_pipeline_chat_data
    WHERE
    NOT EXISTS (SELECT 1 FROM chat_names WHERE chat_names.id=ci_pipeline_chat_data.chat_name_id)
    SQL

    add_concurrent_foreign_key(:ci_pipeline_chat_data, :chat_names, name: "fk_rails_f300456b63", column: :chat_name_id, target_column: :id, on_delete: "cascade")
  end
end
