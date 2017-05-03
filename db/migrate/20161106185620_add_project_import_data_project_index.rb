class AddProjectImportDataProjectIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :project_import_data, :project_id
  end
end
