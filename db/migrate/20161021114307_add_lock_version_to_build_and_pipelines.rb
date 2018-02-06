# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLockVersionToBuildAndPipelines < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :ci_builds, :lock_version, :integer
    add_column :ci_commits, :lock_version, :integer
  end
end
