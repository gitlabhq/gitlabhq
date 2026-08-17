# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills work_item_positions.relative_positioning_namespace_id with the work item's
    # positioning root (Namespace#work_item_positioning_root): the project namespace for
    # projects under a personal (user) namespace, otherwise the root ancestor (traversal_ids[1]).
    class BackfillWorkItemPositionsRelativePositioningNamespaceId < BatchedMigrationJob
      operation_name :backfill_work_item_positions_relative_positioning_namespace_id
      feature_category :team_planning
      cursor :work_item_id

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              WITH sub_batch AS MATERIALIZED (
                #{sub_batch.select(:work_item_id).limit(sub_batch_size).to_sql}
              )
              UPDATE work_item_positions wip
              SET relative_positioning_namespace_id = (
                CASE
                  WHEN p.type = 'User' OR p.type IS NULL THEN n.id
                  ELSE COALESCE(n.traversal_ids[1], n.id)
                END
              )
              FROM namespaces n
              LEFT JOIN namespaces p ON p.id = n.parent_id
              WHERE n.id = wip.namespace_id
                AND wip.work_item_id IN (SELECT work_item_id FROM sub_batch)
            SQL
          )
        end
      end
    end
  end
end
