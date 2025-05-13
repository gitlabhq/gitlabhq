# frozen_string_literal: true

class CopyGlobalPushRuleIntoOrganizationPushRules < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return if organization_push_rules_exist?
    return unless global_push_rule_exists?

    connection.execute(<<~SQL)
      INSERT INTO organization_push_rules (
         organization_id,
         max_file_size,
         member_check,
         prevent_secrets,
         commit_committer_name_check,
         deny_delete_tag,
         reject_unsigned_commits,
         commit_committer_check,
         reject_non_dco_commits,
         commit_message_regex,
         branch_name_regex,
         commit_message_negative_regex,
         author_email_regex,
         file_name_regex,
         created_at,
         updated_at
      )
      SELECT
         organization_id,
         max_file_size,
         member_check,
         prevent_secrets,
         commit_committer_name_check,
         deny_delete_tag,
         reject_unsigned_commits,
         commit_committer_check,
         reject_non_dco_commits,
         commit_message_regex,
         branch_name_regex,
         commit_message_negative_regex,
         author_email_regex,
         file_name_regex,
         created_at,
         updated_at
      FROM push_rules
      WHERE is_sample = TRUE
      ORDER BY id
      LIMIT 1
    SQL
  end

  def down
    connection.execute(<<~SQL)
      DELETE FROM organization_push_rules
      WHERE organization_id IN (
        SELECT organization_id
        FROM push_rules
        WHERE is_sample = TRUE
        LIMIT 1
      )
    SQL
  end

  private

  def organization_push_rules_exist?
    connection.execute("SELECT 1 FROM organization_push_rules LIMIT 1").any?
  end

  def global_push_rule_exists?
    connection.execute("SELECT 1 FROM push_rules WHERE is_sample = TRUE LIMIT 1").any?
  end
end
