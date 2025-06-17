# frozen_string_literal: true

class AddActiveColumnToGroupExternalStreamingDestinations < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def up
    add_column :audit_events_group_external_streaming_destinations, :active, :boolean, null: false, default: true
  end

  def down
    remove_column :audit_events_group_external_streaming_destinations, :active
  end
end
