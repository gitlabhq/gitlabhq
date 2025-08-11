# frozen_string_literal: true

class DropPartitionedSentNotificationsEmailParticipantFk < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.3'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        :sent_notifications_7abbf02cb6,
        :issue_email_participants,
        column: :issue_email_participant_id
      )
    end
  end

  def down
    add_concurrent_partitioned_foreign_key(
      :sent_notifications_7abbf02cb6,
      :issue_email_participants,
      column: :issue_email_participant_id,
      on_delete: :cascade
    )
  end
end
