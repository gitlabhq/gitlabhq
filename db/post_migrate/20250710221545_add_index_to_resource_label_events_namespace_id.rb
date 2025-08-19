# frozen_string_literal: true

class AddIndexToResourceLabelEventsNamespaceId < Gitlab::Database::Migration[2.3]
  NAME = 'index_resource_label_events_on_namespace_id'

  milestone '18.3'
  disable_ddl_transaction!

  def up
    add_concurrent_index :resource_label_events, :namespace_id, name: NAME # rubocop:disable Migration/PreventIndexCreation -- Sharding key is an exception
  end

  def down
    remove_concurrent_index_by_name :resource_label_events, NAME
  end
end
