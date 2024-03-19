# frozen_string_literal: true

class RenameTypeColumnOfGroupExternalStreamingDestination < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  def change
    rename_column :audit_events_group_external_streaming_destinations, :type, :category
  end
end
