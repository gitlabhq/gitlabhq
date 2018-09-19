class BackfillRunnerTypeForCiRunnersPostMigrate < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INSTANCE_RUNNER_TYPE = 1
  PROJECT_RUNNER_TYPE = 3

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/UpdateColumnInBatches
    update_column_in_batches(:ci_runners, :runner_type, INSTANCE_RUNNER_TYPE) do |table, query|
      query.where(table[:is_shared].eq(true)).where(table[:runner_type].eq(nil))
    end

    update_column_in_batches(:ci_runners, :runner_type, PROJECT_RUNNER_TYPE) do |table, query|
      query.where(table[:is_shared].eq(false)).where(table[:runner_type].eq(nil))
    end
  end

  def down
  end
end
