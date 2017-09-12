class AddIndexOnCiBuildsProtected < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, :protected
  end

  def down
    remove_concurrent_index :ci_builds, :protected if index_exists?(:ci_builds, :protected)
  end
end
