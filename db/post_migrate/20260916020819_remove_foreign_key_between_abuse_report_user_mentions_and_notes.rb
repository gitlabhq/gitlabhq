# frozen_string_literal: true

class RemoveForeignKeyBetweenAbuseReportUserMentionsAndNotes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  SOURCE_TABLE_NAME = :abuse_report_user_mentions
  TARGET_TABLE_NAME = :notes
  COLUMN = :note_id
  FOREIGN_KEY_NAME = :fk_a4bd02b7df

  def up
    with_lock_retries do
      remove_foreign_key_if_exists SOURCE_TABLE_NAME, TARGET_TABLE_NAME, column: COLUMN,
        name: FOREIGN_KEY_NAME
    end
  end

  def down
    add_concurrent_foreign_key SOURCE_TABLE_NAME, TARGET_TABLE_NAME, column: COLUMN,
      on_delete: :cascade, name: FOREIGN_KEY_NAME, reverse_lock_order: true
  end
end
