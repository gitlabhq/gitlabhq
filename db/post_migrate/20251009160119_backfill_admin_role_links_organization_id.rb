# frozen_string_literal: true

class BackfillAdminRoleLinksOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.6'

  BATCH_SIZE = 1000
  DEFAULT_ORGANIZATION_ID = 1

  def up
    define_batchable_model('ldap_admin_role_links')
      .each_batch(of: BATCH_SIZE) do |batch|
      batch.where(organization_id: nil).update_all(organization_id: DEFAULT_ORGANIZATION_ID)
    end
  end

  def down
    # no-op
  end
end
