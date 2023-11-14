# frozen_string_literal: true

class IndexOrgIdOnProjects < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_projects_on_organization_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation
    add_concurrent_index :projects, :organization_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end
end
