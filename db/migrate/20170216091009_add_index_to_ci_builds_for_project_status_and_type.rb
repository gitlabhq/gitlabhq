class AddIndexToCiBuildsForProjectStatusAndType < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :ci_builds, [:project_id, :status, :type]
  end
end
