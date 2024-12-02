# frozen_string_literal: true

class AddIndexSentNotificationsOnIssueEmailParticipantId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  INDEX_NAME = 'index_sent_notifications_on_issue_email_participant_id'

  def up
    add_concurrent_index :sent_notifications, :issue_email_participant_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sent_notifications, INDEX_NAME
  end
end
