# frozen_string_literal: true

class AddPartitionedFkToSentNotificationsIssueEmailParticipantId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.2'

  def up
    add_concurrent_partitioned_foreign_key(
      :sent_notifications_7abbf02cb6,
      :issue_email_participants,
      column: :issue_email_participant_id,
      on_delete: :cascade
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :sent_notifications_7abbf02cb6,
        :issue_email_participants,
        column: :issue_email_participant_id
      )
    end
  end
end
