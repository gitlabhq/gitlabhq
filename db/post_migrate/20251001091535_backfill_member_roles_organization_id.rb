# frozen_string_literal: true

class BackfillMemberRolesOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 1000
  DEFAULT_ORGANIZATION_ID = 1

  def up
    define_batchable_model('member_roles')
      .where(organization_id: nil)
      .where(namespace_id: nil)
      .each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(organization_id: DEFAULT_ORGANIZATION_ID)
    end
  end

  def down
    # no-op
  end
end
