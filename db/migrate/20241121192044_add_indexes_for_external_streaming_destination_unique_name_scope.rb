# frozen_string_literal: true

class AddIndexesForExternalStreamingDestinationUniqueNameScope < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.7'

  def up
    add_concurrent_index :audit_events_group_external_streaming_destinations,
      [:group_id, :category, :name],
      unique: true,
      name: 'unique_idx_group_destinations_on_name_category_group'

    add_concurrent_index :audit_events_instance_external_streaming_destinations,
      [:category, :name],
      unique: true,
      name: 'unique_idx_instance_destinations_on_name_category'

    remove_concurrent_index_by_name :audit_events_group_external_streaming_destinations,
      'idx_audit_events_group_external_destinations_on_group_id'
  end

  def down
    remove_concurrent_index_by_name :audit_events_group_external_streaming_destinations,
      'unique_idx_group_destinations_on_name_category_group'

    remove_concurrent_index_by_name :audit_events_instance_external_streaming_destinations,
      'unique_idx_instance_destinations_on_name_category'

    add_concurrent_index :audit_events_group_external_streaming_destinations, :group_id,
      name: 'idx_audit_events_group_external_destinations_on_group_id'
  end
end
