# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSentNotificationsAfterPartition < BatchedMigrationJob # rubocop:disable Metrics/ClassLength -- Necessary for migration
      operation_name :insert_batch # This is used as the key on collecting metrics
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          update_issue_records(sub_batch)
          update_merge_request_records(sub_batch)
          update_commit_records(sub_batch)
          update_epic_records(sub_batch)
          update_project_snippet_records(sub_batch)
          update_design_records(sub_batch)
          update_wiki_records(sub_batch)
        end
      end

      private

      def update_issue_records(sub_batch)
        connection.execute(
          <<~SQL
            #{query_prefix(sub_batch, 'Issue')}
            issues.namespace_id
            FROM
              filtered_relation
              INNER JOIN issues ON filtered_relation.noteable_id = issues.id
            ON CONFLICT DO NOTHING
          SQL
        )
      end

      def update_merge_request_records(sub_batch)
        connection.execute(
          <<~SQL
            #{query_prefix(sub_batch, 'MergeRequest')}
            projects.project_namespace_id
            FROM
              filtered_relation
              INNER JOIN merge_requests ON filtered_relation.noteable_id = merge_requests.id
              INNER JOIN projects ON projects.id = merge_requests.target_project_id
            ON CONFLICT DO NOTHING
          SQL
        )
      end

      def update_commit_records(sub_batch)
        connection.execute(
          <<~SQL
            #{query_prefix(sub_batch, 'Commit')}
            projects.project_namespace_id
            FROM
              filtered_relation
              INNER JOIN projects ON projects.id = filtered_relation.project_id
            ON CONFLICT DO NOTHING
          SQL
        )
      end

      def update_epic_records(sub_batch)
        connection.execute(
          <<~SQL
            #{query_prefix(sub_batch, 'Epic')}
            epics.group_id
            FROM
              filtered_relation
              INNER JOIN epics ON filtered_relation.noteable_id = epics.id
            ON CONFLICT DO NOTHING
          SQL
        )
      end

      def update_project_snippet_records(sub_batch)
        connection.execute(
          <<~SQL
            #{query_prefix(sub_batch, 'ProjectSnippet')}
            projects.project_namespace_id
            FROM
              filtered_relation
              INNER JOIN snippets ON filtered_relation.noteable_id = snippets.id
              INNER JOIN projects ON projects.id = snippets.project_id
            ON CONFLICT DO NOTHING
          SQL
        )
      end

      def update_design_records(sub_batch)
        connection.execute(
          <<~SQL
            #{query_prefix(sub_batch, 'DesignManagement::Design')}
            design_management_designs.namespace_id
            FROM
              filtered_relation
              INNER JOIN design_management_designs ON filtered_relation.noteable_id = design_management_designs.id
            ON CONFLICT DO NOTHING
          SQL
        )
      end

      def update_wiki_records(sub_batch)
        connection.execute(
          <<~SQL
            #{query_prefix(sub_batch, 'WikiPage::Meta')}
            coalesce(wiki_page_meta.namespace_id, projects.project_namespace_id)
            FROM
              filtered_relation
              INNER JOIN wiki_page_meta ON filtered_relation.noteable_id = wiki_page_meta.id
              LEFT JOIN projects ON projects.id = wiki_page_meta.project_id
            ON CONFLICT DO NOTHING
          SQL
        )
      end

      def query_prefix(sub_batch, noteable_type)
        <<~SQL
          WITH relation AS (
            #{sub_batch.limit(sub_batch_size).to_sql}
          ),
          filtered_relation AS (
            SELECT * FROM relation WHERE noteable_type = '#{noteable_type}' LIMIT #{sub_batch_size}
          )
          -- Insert batch, including the sharding key value
          INSERT INTO sent_notifications_7abbf02cb6 (
            id, project_id, noteable_type, noteable_id,
            recipient_id, commit_id, reply_key,
            in_reply_to_discussion_id, issue_email_participant_id,
            created_at, namespace_id
          )
          SELECT
            filtered_relation.id,
            filtered_relation.project_id,
            filtered_relation.noteable_type,
            filtered_relation.noteable_id,
            filtered_relation.recipient_id,
            filtered_relation.commit_id,
            filtered_relation.reply_key,
            filtered_relation.in_reply_to_discussion_id,
            filtered_relation.issue_email_participant_id,
            filtered_relation.created_at,
        SQL
      end
    end
  end
end
