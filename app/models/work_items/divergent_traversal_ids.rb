# frozen_string_literal: true

module WorkItems
  # Finds namespaces whose oldest updated work_item carries a
  # namespace_traversal_ids value that no longer matches the namespace's
  # traversal_ids.
  # We look at the oldest work_item within the namespace, because the
  # namespace_traversal_ids get auto-fixed on work_item updates and with it the `updated_at`.
  class DivergentTraversalIds
    def self.among(namespace_ids)
      new(namespace_ids).among
    end

    def initialize(namespace_ids)
      @namespace_ids = namespace_ids
    end

    def among
      divergent_namespace_ids
    end

    private

    attr_reader :namespace_ids

    def divergent_namespace_ids
      return [] if namespace_ids.empty?

      Namespace
        .where(id: namespace_ids)
        .where(oldest_work_item_diverges)
        .limit(namespace_ids.size)
        .pluck(:id)
    end

    def oldest_work_item_diverges
      oldest_work_item = WorkItem
        .where(WorkItem.arel_table[:namespace_id].eq(Namespace.arel_table[:id]))
        .order(:updated_at, :id)
        .limit(1)
        .select(:namespace_traversal_ids)

      <<~SQL.squish
        EXISTS (
          SELECT 1 FROM (#{oldest_work_item.to_sql}) oldest_work_item
          WHERE oldest_work_item.namespace_traversal_ids IS DISTINCT FROM namespaces.traversal_ids::bigint[]
        )
      SQL
    end
  end
end
