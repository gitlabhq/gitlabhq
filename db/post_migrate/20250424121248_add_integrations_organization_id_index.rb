# frozen_string_literal: true

class AddIntegrationsOrganizationIdIndex < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  disable_ddl_transaction!

  INDEX_NAME = 'index_integrations_on_organization_id'

  def up
    add_concurrent_index :integrations, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :integrations, INDEX_NAME
  end
end
