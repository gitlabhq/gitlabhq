# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class AddIndexToParentId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:namespaces, [:parent_id, :id], unique: true)
  end

  def down
    remove_index :namespaces, [:parent_id, :id] if index_exists? :namespaces, [:parent_id, :id]
  end
end
