# frozen_string_literal: true

class FillAiDuoChatEventsOrganizationId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.10'

  def up
    return unless Gitlab.ee? # Only EE has proper table partitions and data.

    chat_events = define_batchable_model(:ai_duo_chat_events)

    chat_events.each_batch(of: 1000, column: :id) do |batch|
      batch.where(organization_id: nil).update_all(organization_id: 1) # DEFAULT_ORGANIZATION_ID
    end
  end

  def down
    # no-op
  end
end
