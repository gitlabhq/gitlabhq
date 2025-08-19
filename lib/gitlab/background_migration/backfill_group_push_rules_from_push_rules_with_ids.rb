# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillGroupPushRulesFromPushRulesWithIds < BatchedMigrationJob
      operation_name :backfill_group_push_rules_from_push_rules_with_ids
      feature_category :source_code_management

      def perform
        each_sub_batch do |sub_batch|
          backfill_group_push_rules_batch(sub_batch)
        end
      end

      def backfill_group_push_rules_batch(sub_batch)
        connection.execute(<<~SQL)
          INSERT INTO group_push_rules (
            id, group_id, max_file_size, member_check, prevent_secrets, commit_committer_name_check,
            deny_delete_tag, reject_unsigned_commits, commit_committer_check, reject_non_dco_commits,
            commit_message_regex, branch_name_regex, commit_message_negative_regex, author_email_regex,
            file_name_regex, created_at, updated_at
          )
          SELECT
            pr.id, n.id as group_id, pr.max_file_size, pr.member_check, pr.prevent_secrets, pr.commit_committer_name_check,
            pr.deny_delete_tag, pr.reject_unsigned_commits, pr.commit_committer_check, pr.reject_non_dco_commits,
            pr.commit_message_regex, pr.branch_name_regex, pr.commit_message_negative_regex, pr.author_email_regex,
            pr.file_name_regex, pr.created_at, pr.updated_at
          FROM push_rules pr
          INNER JOIN namespaces n ON n.push_rule_id = pr.id
          WHERE pr.id BETWEEN #{sub_batch.min.id} AND #{sub_batch.max.id} AND n.type = 'Group'
          ON CONFLICT (id) DO UPDATE SET
            group_id = EXCLUDED.group_id,
            max_file_size = EXCLUDED.max_file_size,
            member_check = EXCLUDED.member_check,
            prevent_secrets = EXCLUDED.prevent_secrets,
            commit_committer_name_check = EXCLUDED.commit_committer_name_check,
            deny_delete_tag = EXCLUDED.deny_delete_tag,
            reject_unsigned_commits = EXCLUDED.reject_unsigned_commits,
            commit_committer_check = EXCLUDED.commit_committer_check,
            reject_non_dco_commits = EXCLUDED.reject_non_dco_commits,
            commit_message_regex = EXCLUDED.commit_message_regex, branch_name_regex = EXCLUDED.branch_name_regex,
            commit_message_negative_regex = EXCLUDED.commit_message_negative_regex,
            author_email_regex = EXCLUDED.author_email_regex, file_name_regex = EXCLUDED.file_name_regex,
            created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at;
        SQL
      end
    end
  end
end
