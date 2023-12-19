# frozen_string_literal: true

class IndexProjectsOnOrganizationIdAndId < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  INDEX_NAME = "index_projects_on_organization_id_and_id"

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Replacing existing index
    # on organization_id with an index on (organization_id, id)
    add_concurrent_index :projects, [:organization_id, :id], name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index :projects, [:organization_id, :id], name: INDEX_NAME
  end
end
