# frozen_string_literal: true

class AddIndexCiProjectMirrorsOnOrganizationIdAndProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_project_mirrors_on_organization_id_and_project_id'

  # Covers the data isolation subquery (SELECT project_id WHERE
  # organization_id = ?) with an index-only scan.
  def up
    add_concurrent_index :ci_project_mirrors, [:organization_id, :project_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_project_mirrors, INDEX_NAME
  end
end
