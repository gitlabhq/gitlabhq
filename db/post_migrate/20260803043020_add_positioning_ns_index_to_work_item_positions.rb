# frozen_string_literal: true

class AddPositioningNsIndexToWorkItemPositions < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_wi_positions_on_positioning_ns_id_and_relative_position'

  def up
    add_concurrent_index(
      :work_item_positions,
      [:relative_positioning_namespace_id, :relative_position],
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:work_item_positions, INDEX_NAME)
  end
end
