# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class AddUniqueIndexForEnvironmentSlug < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Adding a *unique* index to environments.slug'

  disable_ddl_transaction!

  def up
    add_concurrent_index :environments, [:project_id, :slug], unique: true
  end

  def down
    remove_index :environments, [:project_id, :slug] if index_exists? :environments, [:project_id, :slug]
  end
end
