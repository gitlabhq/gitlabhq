# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateNonDuplicatePushRulesToProjectPushRules < BatchedMigrationJob
      operation_name :migrate_non_duplicate_push_rules_to_project_push_rules
      feature_category :source_code_management

      def perform
        each_sub_batch do |sub_batch|
          backfill_none_duplicate_project_push_rules(sub_batch)
        end
      end

      def backfill_none_duplicate_project_push_rules(sub_batch)
        connection.execute(<<~SQL)
          INSERT INTO project_push_rules (
            id, project_id, max_file_size, member_check, prevent_secrets,
            commit_committer_name_check, deny_delete_tag, reject_unsigned_commits,
            commit_committer_check, reject_non_dco_commits, commit_message_regex,
            branch_name_regex, commit_message_negative_regex, author_email_regex,
            file_name_regex, created_at, updated_at
          )
          SELECT
            pr.id, pr.project_id, pr.max_file_size, pr.member_check, pr.prevent_secrets,
            pr.commit_committer_name_check, pr.deny_delete_tag, pr.reject_unsigned_commits,
            pr.commit_committer_check, pr.reject_non_dco_commits, pr.commit_message_regex,
            pr.branch_name_regex, pr.commit_message_negative_regex, pr.author_email_regex,
            pr.file_name_regex, pr.created_at, pr.updated_at
          FROM push_rules pr
          WHERE pr.id BETWEEN #{sub_batch.minimum(:id)} AND #{sub_batch.maximum(:id)}
            AND pr.project_id IS NOT NULL AND pr.is_sample = FALSE
            AND NOT EXISTS (
              SELECT 1
              FROM push_rules pr2
              WHERE pr2.project_id = pr.project_id
                AND pr2.id != pr.id AND pr2.is_sample = FALSE
            )
            AND NOT EXISTS (
              SELECT 1
              FROM project_push_rules ppr
              WHERE ppr.project_id = pr.project_id
            )
          ON CONFLICT (id) DO NOTHING
        SQL
      end
    end
  end
end
