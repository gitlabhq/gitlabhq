# frozen_string_literal: true

class BackfillScimOauthAccessTokensGroupOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 500

  def up
    define_batchable_model('scim_oauth_access_tokens')
      .where(organization_id: nil)
      .where.not(group_id: nil)
      .each_batch(of: BATCH_SIZE) do |batch|
        batch.update_all(<<~SQL)
          organization_id = (
            SELECT organization_id FROM namespaces
            WHERE namespaces.id = scim_oauth_access_tokens.group_id
          )
        SQL
        sleep(0.1)
      end
  end

  def down
    # no-op
  end
end
