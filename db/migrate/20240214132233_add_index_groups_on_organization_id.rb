# frozen_string_literal: true

class AddIndexGroupsOnOrganizationId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  TABLE_NAME = :namespaces
  INDEX_NAME = 'index_namespaces_on_organization_id_for_groups'
  CLAUSE = "((type)::text = 'Group'::text)"

  def up
    add_concurrent_index TABLE_NAME, :organization_id, name: INDEX_NAME, where: CLAUSE
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
