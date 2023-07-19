# frozen_string_literal: true

class AddNameToExternalAuditEventDestination < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  # text limit is added in a 20230612091526_add_text_limit_to_external_audit_event_destination_name.rb migration
  def change
    add_column :audit_events_external_audit_event_destinations, :name, :text
  end

  # rubocop:enable Migration/AddLimitToTextColumns
end
