# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddNotNullConstraintAbuseReportUserMentionToOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  def up
    add_not_null_constraint :abuse_report_user_mentions, :organization_id
  end

  def down
    remove_not_null_constraint :abuse_report_user_mentions, :organization_id
  end
end
