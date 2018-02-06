# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class AddNameIndexToNamespace < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_concurrent_index(:namespaces, [:name, :parent_id], unique: true)
  end

  def down
    if index_exists?(:namespaces, [:name, :parent_id])
      remove_index :namespaces, [:name, :parent_id]
    end
  end
end
