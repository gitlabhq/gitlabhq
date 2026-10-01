# frozen_string_literal: true

class AddUniqueIndexOnIntegrationsTypeNewOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  INDEX_NAME = 'index_integrations_on_type_new_and_organization_id_unique'

  def up
    add_concurrent_index :integrations, [:type_new, :organization_id],
      unique: true,
      where: 'instance = true',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :integrations, INDEX_NAME
  end
end
