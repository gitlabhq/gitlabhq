# frozen_string_literal: true

class RemoveSentNotificationsIssueEmailParticipantsFk < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :sent_notifications, :issue_email_participants, column: :issue_email_participant_id
    end
  end

  def down
    add_concurrent_foreign_key :sent_notifications,
      :issue_email_participants,
      column: :issue_email_participant_id,
      on_delete: :nullify,
      validate: false
  end
end
