# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class AddIndexOnRunnersLocked < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_runners, :locked
  end

  def down
    remove_index :ci_runners, :locked if index_exists? :ci_runners, :locked
  end
end
