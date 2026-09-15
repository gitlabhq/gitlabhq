# frozen_string_literal: true

class AddIndexCiNamespaceMirrorsOnOrganizationIdAndNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_namespace_mirrors_on_organization_id_and_namespace_id'

  # Covers the data isolation subquery (SELECT namespace_id WHERE
  # organization_id = ?) with an index-only scan.
  def up
    add_concurrent_index :ci_namespace_mirrors, [:organization_id, :namespace_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_namespace_mirrors, INDEX_NAME
  end
end
