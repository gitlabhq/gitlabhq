# frozen_string_literal: true

class RemoveIntegrationsIndexOnIdInstanceProjectIdOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_idx_integrations_on_id_instance_project_id_organization_id'

  def up
    remove_concurrent_index_by_name :integrations, INDEX_NAME
  end

  def down
    add_concurrent_index(
      :integrations,
      :id,
      where: 'instance = FALSE AND project_id IS NOT NULL AND organization_id IS NOT NULL',
      name: INDEX_NAME
    )
  end
end
