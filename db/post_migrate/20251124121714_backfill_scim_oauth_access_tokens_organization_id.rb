# frozen_string_literal: true

class BackfillScimOauthAccessTokensOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 100
  DEFAULT_ORGANIZATION_ID = 1

  def up
    define_batchable_model('scim_oauth_access_tokens')
      .where(organization_id: nil)
      .where(group_id: nil)
      .each_batch(of: BATCH_SIZE) do |batch|
        batch.update_all(organization_id: DEFAULT_ORGANIZATION_ID)
        sleep(0.1)
      end
  end

  def down
    # no-op
  end
end
