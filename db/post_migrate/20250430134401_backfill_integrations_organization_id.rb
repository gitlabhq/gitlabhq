# frozen_string_literal: true

class BackfillIntegrationsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.0'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell
  disable_ddl_transaction!

  def up
    integrations = define_batchable_model('integrations')

    integrations.where(instance: true, organization_id: nil).each_batch do |batch|
      batch.update_all(organization_id: 1)
    end
  end

  def down
    # no-op
  end
end
