# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateDuplicatePushRulesToProjectPushRules < BatchedMigrationJob
      operation_name :migrate_duplicate_push_rules_to_project_push_rules
      feature_category :source_code_management

      class PushRule < ::ApplicationRecord
        self.table_name = 'push_rules'
      end

      class ProjectPushRule < ::ApplicationRecord
        self.table_name = 'project_push_rules'
      end

      def perform
        each_sub_batch do |sub_batch|
          if Gitlab.com_except_jh? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks  -- migration is for .com_except_jh? only.
            migrate_duplicates_with_explicit_ordering(sub_batch)
          else
            migrate_duplicates_with_implicit_ordering(sub_batch)
          end
        end
      end

      private

      def migrate_duplicates_with_explicit_ordering(sub_batch)
        # For GitLab.com: Use simple ORDER BY ID: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200182
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
          INNER JOIN projects p ON p.id = pr.project_id
          WHERE p.id BETWEEN #{sub_batch.minimum(:id)} AND #{sub_batch.maximum(:id)}
            AND pr.is_sample = FALSE
            AND EXISTS (
              SELECT 1 FROM push_rules pr2
              WHERE pr2.project_id = pr.project_id AND pr2.id != pr.id AND pr2.is_sample = FALSE
            )
            AND pr.id = (
              SELECT MIN(pr3.id) FROM push_rules pr3 WHERE pr3.project_id = pr.project_id AND pr3.is_sample = FALSE
            )
            AND NOT EXISTS (
              SELECT 1 FROM project_push_rules ppr WHERE ppr.project_id = pr.project_id
            )
          ON CONFLICT (id) DO NOTHING
        SQL
      end

      def migrate_duplicates_with_implicit_ordering(sub_batch)
        # Maintains existing behavior(project.push_rule): SELECT * FROM push_rules WHERE project_id = X LIMIT 1

        project_ids = sub_batch.pluck(:id).compact

        duplicate_project_ids = find_duplicate_project_ids(project_ids)
        return if duplicate_project_ids.blank?

        duplicate_project_ids = filter_already_migrated(duplicate_project_ids)
        return if duplicate_project_ids.blank?

        migrate_each_duplicate(duplicate_project_ids)
      end

      def find_duplicate_project_ids(project_ids)
        PushRule
          .where(project_id: project_ids, is_sample: false)
          .group(:project_id).having('COUNT(*) > 1').pluck(:project_id)
      end

      def filter_already_migrated(duplicate_project_ids)
        already_migrated = ProjectPushRule
          .where(project_id: duplicate_project_ids)
          .pluck(:project_id)

        duplicate_project_ids.reject { |id| already_migrated.include?(id) }
      end

      def migrate_each_duplicate(duplicate_project_ids)
        duplicate_project_ids.each do |project_id|
          push_rule = PushRule.where(project_id: project_id).limit(1).first

          ProjectPushRule.insert(
            {
              id: push_rule.id,
              project_id: push_rule.project_id,
              max_file_size: push_rule.max_file_size,
              member_check: push_rule.member_check,
              prevent_secrets: push_rule.prevent_secrets,
              commit_committer_name_check: push_rule.commit_committer_name_check,
              deny_delete_tag: push_rule.deny_delete_tag,
              reject_unsigned_commits: push_rule.reject_unsigned_commits,
              commit_committer_check: push_rule.commit_committer_check,
              reject_non_dco_commits: push_rule.reject_non_dco_commits,
              commit_message_regex: push_rule.commit_message_regex,
              branch_name_regex: push_rule.branch_name_regex,
              commit_message_negative_regex: push_rule.commit_message_negative_regex,
              author_email_regex: push_rule.author_email_regex,
              file_name_regex: push_rule.file_name_regex,
              created_at: push_rule.created_at,
              updated_at: push_rule.updated_at
            }
          )
        rescue ActiveRecord::RecordNotUnique
          next
        end
      end
    end
  end
end
