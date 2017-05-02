class EnableAutoCancelPendingPipelinesForAll < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    connection.execute(
      'UPDATE projects SET auto_cancel_pending_pipelines = 1')
  end

  def down
    # Nothing we can do!
  end
end
