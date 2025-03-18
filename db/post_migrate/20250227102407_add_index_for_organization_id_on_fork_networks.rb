# frozen_string_literal: true

class AddIndexForOrganizationIdOnForkNetworks < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  TABLE_NAME = :fork_networks
  INDEX_NAME = 'index_fork_networks_on_organization_id'

  def up
    add_concurrent_index TABLE_NAME, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
