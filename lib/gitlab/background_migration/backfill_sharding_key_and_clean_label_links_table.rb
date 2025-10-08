# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillShardingKeyAndCleanLabelLinksTable < BatchedMigrationJob
      operation_name :set_namespace_id_and_delete_orphaned_records
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          handle_issue_related_records(sub_batch)
          handle_merge_request_related_records(sub_batch)
          handle_epic_related_records(sub_batch)
          delete_and_archive_label_links_with_no_namespace(sub_batch)
        end
      end

      private

      def common_query(sub_batch, target_type)
        <<~SQL
          WITH relation AS MATERIALIZED (
            #{sub_batch.limit(sub_batch_size).to_sql}
          ), filtered_relation AS MATERIALIZED (
            SELECT * from relation WHERE "target_type" = '#{target_type}' LIMIT #{sub_batch_size}
          )
          #{yield}
        SQL
      end

      def handle_issue_related_records(sub_batch)
        connection.execute(
          common_query(sub_batch, 'Issue') do
            <<~SQL
              UPDATE "label_links"
              SET "namespace_id" = "issues"."namespace_id"
              FROM filtered_relation INNER JOIN "issues" ON "issues"."id" = filtered_relation."target_id"
              WHERE "label_links"."id" = filtered_relation."id"
            SQL
          end
        )
      end

      def handle_merge_request_related_records(sub_batch)
        connection.execute(
          common_query(sub_batch, 'MergeRequest') do
            <<~SQL
              UPDATE "label_links"
              SET "namespace_id" = "projects"."project_namespace_id"
              FROM filtered_relation INNER JOIN "merge_requests" ON "merge_requests"."id" = filtered_relation."target_id"
              INNER JOIN "projects" ON "projects"."id" = "merge_requests"."target_project_id"
              WHERE "label_links"."id" = filtered_relation."id"
            SQL
          end
        )
      end

      def handle_epic_related_records(sub_batch)
        connection.execute(
          common_query(sub_batch, 'Epic') do
            <<~SQL
              UPDATE "label_links"
              SET "namespace_id" = "epics"."group_id"
              FROM filtered_relation INNER JOIN "epics" ON "epics"."id" = filtered_relation."target_id"
              WHERE "label_links"."id" = filtered_relation."id"
            SQL
          end
        )
      end

      def delete_and_archive_label_links_with_no_namespace(sub_batch)
        connection.execute(<<~SQL)
          WITH relation AS MATERIALIZED (
            #{sub_batch.limit(sub_batch_size).to_sql}
          ), filtered_relation AS MATERIALIZED (
            SELECT * from relation WHERE "namespace_id" IS NULL LIMIT #{sub_batch_size}
          ), deleted_links AS MATERIALIZED (
            DELETE FROM "label_links" WHERE "id" IN (SELECT "id" FROM filtered_relation)
            RETURNING #{label_links_columns_for_archive}
          )
          INSERT INTO label_links_archived (#{label_links_columns_for_archive})
          SELECT #{label_links_columns_for_archive}
          FROM deleted_links
        SQL
      end

      def label_links_columns_for_archive
        @link_columns ||= %w[id label_id target_id target_type created_at updated_at namespace_id].join(', ')
      end
    end
  end
end
