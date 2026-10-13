# frozen_string_literal: true

class DeleteGroupScimOauthAccessTokens < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    # All rows with group_id set were migrated to group_scim_auth_access_tokens in
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170565.
    # The group_id column will be dropped in a subsequent migration.
    define_batchable_model(:scim_oauth_access_tokens)
      .where.not(group_id: nil)
      .each_batch do |batch|
        batch.delete_all
      end
  end

  def down
    # Rows cannot be restored; this migration is irreversible.
  end
end
