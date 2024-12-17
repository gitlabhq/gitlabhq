# frozen_string_literal: true

class AddIssueEmailParticipantIdToSentNotifications < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :sent_notifications, :issue_email_participant_id, :bigint, null: true
    # rubocop:enable Migration/PreventAddingColumns
  end
end
