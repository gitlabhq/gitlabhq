# frozen_string_literal: true

class BackfillGroupIntegrationsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 50

  def up
    integrations = define_batchable_model('integrations')

    integrations
      .where(instance: false)
      .where.not(group_id: nil)
      .where.not(organization_id: nil)
      .each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(organization_id: nil)
    end
  end

  def down
    # no-op
  end
end
