class AddIndexToLastRepositoryUpdatedAtOnProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:projects, :last_repository_updated_at)
  end

  def down
    remove_concurrent_index(:projects, :last_repository_updated_at) if index_exists?(:projects, :last_repository_updated_at)
  end
end
