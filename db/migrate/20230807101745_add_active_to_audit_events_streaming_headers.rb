# frozen_string_literal: true

class AddActiveToAuditEventsStreamingHeaders < Gitlab::Database::Migration[2.1]
  def change
    add_column :audit_events_streaming_headers, :active, :boolean, default: true, null: false
  end
end
