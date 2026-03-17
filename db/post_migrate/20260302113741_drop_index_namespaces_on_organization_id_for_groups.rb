# frozen_string_literal: true

class DropIndexNamespacesOnOrganizationIdForGroups < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  TABLE = :namespaces
  INDEX = "index_namespaces_on_organization_id_for_groups"

  def up
    remove_concurrent_index_by_name TABLE, INDEX
  end

  def down
    add_concurrent_index TABLE,
      :organization_id,
      name: INDEX,
      where: "type = 'Group'"
  end
end
