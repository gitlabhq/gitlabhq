# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class AddPathIndexToNamespace < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_concurrent_index :namespaces, :path
  end

  def down
    if index_exists?(:namespaces, :path)
      remove_index :namespaces, :path
    end
  end
end
