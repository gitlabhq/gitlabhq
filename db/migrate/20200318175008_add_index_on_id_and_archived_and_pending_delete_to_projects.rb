# frozen_string_literal: true

class AddIndexOnIdAndArchivedAndPendingDeleteToProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_projects_on_id_and_archived_and_pending_delete'

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, :id, where: "archived = FALSE AND pending_delete = FALSE", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end
end
