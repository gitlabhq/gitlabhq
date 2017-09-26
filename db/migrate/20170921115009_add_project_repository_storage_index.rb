class AddProjectRepositoryStorageIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(*index_spec) unless index_exists?(*index_spec)
  end

  def down
    remove_concurrent_index(*index_spec) if index_exists?(*index_spec)
  end

  def index_spec
    [:projects, :repository_storage]
  end
end
