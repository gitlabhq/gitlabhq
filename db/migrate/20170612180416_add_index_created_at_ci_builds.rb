class AddIndexCreatedAtCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, [:project_id, :created_at]
  end

  def down
    if index_exists?  :ci_builds, [:project_id, :created_at]
      remove_concurrent_index :ci_builds, [:project_id, :created_at]
    end
  end
end
