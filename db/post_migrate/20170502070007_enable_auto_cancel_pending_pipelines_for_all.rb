class EnableAutoCancelPendingPipelinesForAll < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    update_column_in_batches(:projects, :auto_cancel_pending_pipelines, 1)
  end

  def down
    # Nothing we can do!
  end
end
