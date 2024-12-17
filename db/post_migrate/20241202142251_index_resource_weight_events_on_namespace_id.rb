# frozen_string_literal: true

class IndexResourceWeightEventsOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_resource_weight_events_on_namespace_id'

  def up
    add_concurrent_index :resource_weight_events, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :resource_weight_events, INDEX_NAME
  end
end
