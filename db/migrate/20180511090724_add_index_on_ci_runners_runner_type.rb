class AddIndexOnCiRunnersRunnerType < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_runners, :runner_type
  end

  def down
    remove_index :ci_runners, :runner_type
  end
end
