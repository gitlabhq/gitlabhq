# frozen_string_literal: true

class AddForeignKeyToIncidentManagementTimelineEventsOnNote < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :incident_management_timeline_events, :notes, column: :promoted_from_note_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :incident_management_timeline_events, column: :promoted_from_note_id
    end
  end
end
