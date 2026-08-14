# frozen_string_literal: true

class RemoveAbuseReportUserMentionsNoteIdFk < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  # `notes` is a high-traffic table, so the removal takes the locks in parent-to-child order
  # (the default for remove_foreign_key_if_exists) and retries rather than blocking.

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :abuse_report_user_mentions, :notes, column: :note_id
    end
  end

  def down
    add_concurrent_foreign_key :abuse_report_user_mentions, :notes, column: :note_id, on_delete: :cascade,
      name: 'fk_a4bd02b7df'
  end
end
