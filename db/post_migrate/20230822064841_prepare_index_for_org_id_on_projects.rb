# frozen_string_literal: true

class PrepareIndexForOrgIdOnProjects < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_projects_on_organization_id'

  def up
    prepare_async_index :projects, :organization_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :projects, :organization_id, name: INDEX_NAME
  end
end
