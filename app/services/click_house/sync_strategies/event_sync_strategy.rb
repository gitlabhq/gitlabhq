# frozen_string_literal: true

module ClickHouse
  module SyncStrategies
    class EventSyncStrategy < BaseSyncStrategy
      # transforms the traversal_ids to a String:
      # Example: group_id/subgroup_id/group_or_projectnamespace_id/
      PATH_COLUMN = <<~SQL
        (
          CASE
            WHEN project_id IS NOT NULL THEN (SELECT array_to_string(traversal_ids, '/') || '/' FROM namespaces WHERE id = (SELECT project_namespace_id FROM projects WHERE id = events.project_id LIMIT 1) LIMIT 1)
            WHEN group_id IS NOT NULL THEN (SELECT array_to_string(traversal_ids, '/') || '/' FROM namespaces WHERE id = events.group_id LIMIT 1)
            ELSE '0/'
          END
        ) AS path
      SQL

      private

      def csv_mapping
        {
          id: :id,
          path: :path,
          author_id: :author_id,
          target_id: :target_id,
          target_type: :target_type,
          action: :raw_action,
          created_at: :casted_created_at,
          updated_at: :casted_updated_at
        }
      end

      def projections
        [
          :id,
          PATH_COLUMN,
          :author_id,
          :target_id,
          :target_type,
          'action AS raw_action',
          'EXTRACT(epoch FROM created_at) AS casted_created_at',
          'EXTRACT(epoch FROM updated_at) AS casted_updated_at'
        ]
      end

      def insert_query
        <<~SQL.squish
          INSERT INTO events (#{csv_mapping.keys.join(', ')})
          SETTINGS async_insert=1, wait_for_async_insert=1 FORMAT CSV
        SQL
      end

      def model_class
        ::Event
      end

      def enabled?
        super && Feature.enabled?(:event_sync_worker_for_click_house)
      end
    end
  end
end
