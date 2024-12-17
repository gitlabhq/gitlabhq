# frozen_string_literal: true

class AddLegacyDestinationIdToExternalStreamingDestinations < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :audit_events_instance_external_streaming_destinations,
      :legacy_destination_ref,
      :bigint,
      null: true,
      default: nil

    add_column :audit_events_group_external_streaming_destinations,
      :legacy_destination_ref,
      :bigint,
      null: true,
      default: nil
  end
end
