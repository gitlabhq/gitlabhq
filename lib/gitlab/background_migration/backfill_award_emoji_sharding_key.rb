# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillAwardEmojiShardingKey < BatchedMigrationJob # rubocop:disable Metrics/ClassLength -- BBMs might need bigger classes
      operation_name :set_award_emoji_sharding_key
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          handle_issue_related_records(sub_batch)
          handle_merge_request_related_records(sub_batch)
          handle_epic_related_records(sub_batch)
          handle_snippet_related_records(sub_batch)
          handle_note_related_records(sub_batch)
          delete_and_archive_award_emoji_with_no_sharding_key(sub_batch)
        end
      end

      private

      def common_query(sub_batch, awardable_type)
        <<~SQL
          WITH relation AS MATERIALIZED (
            #{sub_batch.limit(sub_batch_size).to_sql}
          ), filtered_relation AS MATERIALIZED (
            SELECT * from relation WHERE "awardable_type" = '#{awardable_type}' LIMIT #{sub_batch_size}
          )
          #{yield}
        SQL
      end

      def handle_issue_related_records(sub_batch)
        connection.execute(
          common_query(sub_batch, 'Issue') do
            <<~SQL
              UPDATE "award_emoji"
              SET "namespace_id" = "issues"."namespace_id"
              FROM filtered_relation INNER JOIN "issues" ON "issues"."id" = filtered_relation."awardable_id"
              WHERE "award_emoji"."id" = filtered_relation."id"
            SQL
          end
        )
      end

      def handle_merge_request_related_records(sub_batch)
        connection.execute(
          common_query(sub_batch, 'MergeRequest') do
            <<~SQL
              UPDATE "award_emoji"
              SET "namespace_id" = "projects"."project_namespace_id"
              FROM filtered_relation INNER JOIN "merge_requests" ON "merge_requests"."id" = filtered_relation."awardable_id"
              INNER JOIN "projects" ON "projects"."id" = "merge_requests"."target_project_id"
              WHERE "award_emoji"."id" = filtered_relation."id"
            SQL
          end
        )
      end

      def handle_epic_related_records(sub_batch)
        connection.execute(
          common_query(sub_batch, 'Epic') do
            <<~SQL
              UPDATE "award_emoji"
              SET "namespace_id" = "epics"."group_id"
              FROM filtered_relation INNER JOIN "epics" ON "epics"."id" = filtered_relation."awardable_id"
              WHERE "award_emoji"."id" = filtered_relation."id"
            SQL
          end
        )
      end

      def handle_snippet_related_records(sub_batch)
        connection.execute(
          common_query(sub_batch, 'Snippet') do
            <<~SQL
              UPDATE "award_emoji"
              SET "namespace_id" = "projects"."project_namespace_id", "organization_id" = "snippets"."organization_id"
              FROM filtered_relation INNER JOIN "snippets" ON "snippets"."id" = filtered_relation."awardable_id"
              LEFT JOIN "projects" ON "projects"."id" = "snippets"."project_id"
              WHERE "award_emoji"."id" = filtered_relation."id"
            SQL
          end
        )
      end

      def handle_note_related_records(sub_batch)
        connection.execute(
          common_query(sub_batch, 'Note') do
            <<~SQL
              , relation_with_sk AS MATERIALIZED (
                SELECT "filtered_relation"."id",
                  COALESCE("projects"."project_namespace_id", "notes"."namespace_id") AS namespace_id,
                  CASE
                    WHEN num_nonnulls("notes"."project_id", "notes"."namespace_id") >= 1 THEN NULL
                    ELSE "notes"."organization_id"
                  END AS organization_id
                FROM "filtered_relation" INNER JOIN "notes" ON "notes"."id" = "filtered_relation"."awardable_id"
                LEFT JOIN "projects" ON "projects"."id" = "notes"."project_id"
                LIMIT #{sub_batch_size}
              )
              UPDATE "award_emoji"
              SET "namespace_id" = "relation_with_sk"."namespace_id",
                "organization_id" = "relation_with_sk"."organization_id"
              FROM "relation_with_sk"
              WHERE "award_emoji"."id" = "relation_with_sk"."id"
            SQL
          end
        )
      end

      def delete_and_archive_award_emoji_with_no_sharding_key(sub_batch)
        connection.execute(<<~SQL)
          WITH relation AS MATERIALIZED (
            #{sub_batch.limit(sub_batch_size).to_sql}
          ), filtered_relation AS MATERIALIZED (
            SELECT * from relation WHERE "namespace_id" IS NULL AND "organization_id" IS NULL LIMIT #{sub_batch_size}
          ), deleted_emoji AS MATERIALIZED (
            DELETE FROM "award_emoji" WHERE "id" IN (SELECT "id" FROM filtered_relation)
            RETURNING #{award_emoji_columns_for_archive}
          )
          INSERT INTO award_emoji_archived (#{award_emoji_columns_for_archive})
          SELECT #{award_emoji_columns_for_archive}
          FROM deleted_emoji
        SQL
      end

      def award_emoji_columns_for_archive
        @award_emoji_columns_for_archive ||= %w[
          id name user_id awardable_id awardable_type created_at updated_at namespace_id organization_id
        ].join(', ')
      end
    end
  end
end
