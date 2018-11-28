# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class AddIndexToRoutes < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:routes, :path, unique: true)
    add_concurrent_index(:routes, [:source_type, :source_id], unique: true)
  end

  def down
    remove_index(:routes, :path) if index_exists? :routes, :path
    remove_index(:routes, [:source_type, :source_id]) if index_exists? :routes, [:source_type, :source_id]
  end
end
