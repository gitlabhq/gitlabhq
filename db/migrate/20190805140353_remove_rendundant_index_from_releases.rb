# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveRendundantIndexFromReleases < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :releases, 'index_releases_on_project_id'

    # This is an extra index that is not present in db/schema.rb but known to exist on some installs
    remove_concurrent_index_by_name :releases, 'releases_project_id_idx' if index_exists_by_name?(:releases, 'releases_project_id_idx')
  end

  def down
    add_concurrent_index :releases, :project_id, name: 'index_releases_on_project_id'
  end
end
