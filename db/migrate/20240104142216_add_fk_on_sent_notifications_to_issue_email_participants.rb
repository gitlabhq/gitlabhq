# frozen_string_literal: true

class AddFkOnSentNotificationsToIssueEmailParticipants < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  def up
    add_concurrent_foreign_key(
      :sent_notifications,
      :issue_email_participants,
      column: :issue_email_participant_id,
      on_delete: :nullify,
      validate: false
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :sent_notifications, column: :issue_email_participant_id
    end
  end
end
