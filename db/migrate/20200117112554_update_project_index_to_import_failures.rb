# frozen_string_literal: true

class UpdateProjectIndexToImportFailures < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  PROJECT_INDEX_OLD = 'index_import_failures_on_project_id'
  PROJECT_INDEX_NEW = 'index_import_failures_on_project_id_not_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:import_failures, :project_id, where: 'project_id IS NOT NULL', name: PROJECT_INDEX_NEW)
    remove_concurrent_index_by_name(:import_failures, PROJECT_INDEX_OLD)
  end

  def down
    add_concurrent_index(:import_failures, :project_id, name: PROJECT_INDEX_OLD)
    remove_concurrent_index_by_name(:import_failures, PROJECT_INDEX_NEW)
  end
end
