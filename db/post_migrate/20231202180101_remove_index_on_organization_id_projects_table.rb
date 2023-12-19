# frozen_string_literal: true

class RemoveIndexOnOrganizationIdProjectsTable < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_projects_on_organization_id'

  def up
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end

  def down
    add_concurrent_index :projects, :organization_id, name: INDEX_NAME
  end
end
