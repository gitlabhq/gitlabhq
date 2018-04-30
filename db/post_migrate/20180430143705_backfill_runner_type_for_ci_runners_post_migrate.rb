class BackfillRunnerTypeForCiRunnersPostMigrate < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:ci_runners, :runner_type, 1) do |table, query|
      query.where(table[:is_shared].eq(true)).where(table[:runner_type].eq(nil))
    end

    update_column_in_batches(:ci_runners, :runner_type, 3) do |table, query|
      query.where(table[:is_shared].eq(false)).where(table[:runner_type].eq(nil))
    end
  end

  def down
  end
end
