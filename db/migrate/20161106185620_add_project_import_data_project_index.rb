# rubocop:disable RemoveIndex
class AddProjectImportDataProjectIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_import_data, :project_id
  end

  def down
    remove_index :project_import_data, :project_id if index_exists? :project_import_data, :project_id
  end
end
