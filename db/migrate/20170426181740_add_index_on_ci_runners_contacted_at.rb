# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexOnCiRunnersContactedAt < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_runners, :contacted_at
  end

  def down
    remove_concurrent_index :ci_runners, :contacted_at if index_exists?(:ci_runners, :contacted_at)
  end
end
