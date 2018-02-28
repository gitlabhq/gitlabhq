# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveTemporaryCiBuildsIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # To use create/remove index concurrently
  disable_ddl_transaction!

  def up
    return unless index_exists?(:ci_builds, :id, name: 'index_for_ci_builds_retried_migration')

    remove_concurrent_index(:ci_builds, :id, name: "index_for_ci_builds_retried_migration")
  end

  def down
    # this was a temporary index for a migration that was never
    # present previously so this probably shouldn't be here but it's
    # easier to test the drop if we have a way to create it.
    add_concurrent_index("ci_builds", ["id"],
                         name: "index_for_ci_builds_retried_migration",
                         where: "(retried IS NULL)",
                         using: :btree)
  end
end
