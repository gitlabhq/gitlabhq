# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills resource_link_events from system_note_metadata and notes records
    class BackfillResourceLinkEvents < BatchedMigrationJob
      operation_name :backfill_resource_link_events
      feature_category :team_planning

      # AR model for resource_link_events inlined
      class ResourceLinkEvent < ApplicationRecord
        self.table_name = 'resource_link_events'

        enum action: {
          add: 1,
          remove: 2
        }
      end

      scope_to ->(relation) { relation.where("action='relate_to_parent' OR action='unrelate_from_parent'") }

      def perform
        each_sub_batch do |sub_batch|
          values_subquery = resource_link_event_values_query(sub_batch.select(:id).to_sql)

          connection.execute(<<~SQL)
            INSERT INTO resource_link_events (action, issue_id, child_work_item_id, user_id, created_at, system_note_metadata_id)
             #{values_subquery}
            ON CONFLICT (system_note_metadata_id) DO NOTHING;
          SQL
        end
      end

      def resource_link_event_values_query(ids_subquery)
        <<~SQL
          SELECT
            CASE WHEN system_note_metadata.action='relate_to_parent' THEN #{ResourceLinkEvent.actions[:add]}
            ELSE #{ResourceLinkEvent.actions[:remove]}
            END AS action,
            parent_issues.id AS issue_id,
            notes.noteable_id AS child_work_item_id,
            notes.author_id AS user_id,
            system_note_metadata.created_at AS created_at,
            system_note_metadata.id AS system_note_metadata_id
          FROM system_note_metadata
            INNER JOIN notes ON system_note_metadata.note_id = notes.id
            INNER JOIN issues as work_items ON work_items.id = notes.noteable_id,
          LATERAL (
            -- This lateral join searches for the id of the parent issue.
            --
            -- When a child work item is added to its parent,
            --   "relate_to_parent" is recorded as `system_note_metadata.action`
            --    and a note records to which parent the child work item is added e.g, "added #1 (iid) as parent".
            --
            -- Based on the iid of the parent extracted from the note and using the child work item's project id,
            -- we can find out the id of the parent issue.
            SELECT issues.id
            FROM issues
            WHERE
              issues.project_id = work_items.project_id
              AND issues.iid = CASE WHEN system_note_metadata.action='relate_to_parent' THEN substring(notes.note from 'added #(\\d+) as parent')::bigint
                                ELSE  substring(notes.note from 'removed parent \\S+ #(\\d+)')::bigint
                                END
            ) parent_issues
          WHERE
            system_note_metadata.id IN (#{ids_subquery})
        SQL
      end
    end
  end
end
