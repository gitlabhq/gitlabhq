# frozen_string_literal: true

module WorkItems
  class Position < ApplicationRecord
    self.table_name = 'work_item_positions'

    belongs_to :work_item, class_name: 'WorkItem', inverse_of: :work_item_position
    belongs_to :namespace

    validates :namespace, :work_item, presence: true

    before_validation :copy_namespace_from_work_item

    # Refreshes the positioning root (relative_positioning_namespace_id) for the given
    # work items from each row's own namespace_id (which doesn't change). The CASE mirrors
    # Namespace#work_item_positioning_root and reads traversal_ids from the DB so it stays
    # correct under concurrent transfers.
    def self.refresh_relative_positioning_namespace_id(work_items)
      where(work_item_id: work_items.select(:id)).update_all(
        "relative_positioning_namespace_id = (
            SELECT CASE WHEN p.type = 'User' OR p.type IS NULL THEN n.id
                        ELSE COALESCE(n.traversal_ids[1], n.id) END
            FROM namespaces n LEFT JOIN namespaces p ON p.id = n.parent_id
            WHERE n.id = work_item_positions.namespace_id)"
      )
    end

    private

    def copy_namespace_from_work_item
      self.namespace = work_item&.namespace
    end
  end
end
