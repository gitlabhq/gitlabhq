# frozen_string_literal: true

class AddGroupIdToAuditEventsStreamingHeaders < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :audit_events_streaming_headers, :group_id, :bigint
  end
end
