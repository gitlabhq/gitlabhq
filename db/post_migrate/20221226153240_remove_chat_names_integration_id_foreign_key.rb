# frozen_string_literal: true

class RemoveChatNamesIntegrationIdForeignKey < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :chat_names
  TARGET_TABLE_NAME = :integrations
  COLUMN = :integration_id
  TARGET_COLUMN = :id
  FK_NAME = :fk_99a1348daf

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(SOURCE_TABLE_NAME, name: FK_NAME)
    end
  end

  def down
    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: COLUMN,
      name: FK_NAME,
      on_delete: :cascade
    )
  end
end
