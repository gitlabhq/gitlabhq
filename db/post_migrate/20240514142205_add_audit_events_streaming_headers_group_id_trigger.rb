# frozen_string_literal: true

class AddAuditEventsStreamingHeadersGroupIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :audit_events_streaming_headers,
      sharding_key: :group_id,
      parent_table: :audit_events_external_audit_event_destinations,
      parent_sharding_key: :namespace_id,
      foreign_key: :external_audit_event_destination_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :audit_events_streaming_headers,
      sharding_key: :group_id,
      parent_table: :audit_events_external_audit_event_destinations,
      parent_sharding_key: :namespace_id,
      foreign_key: :external_audit_event_destination_id
    )
  end
end
