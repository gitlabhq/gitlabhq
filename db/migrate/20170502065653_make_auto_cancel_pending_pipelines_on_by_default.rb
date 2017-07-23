class MakeAutoCancelPendingPipelinesOnByDefault < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default(:projects, :auto_cancel_pending_pipelines, 1)
  end

  def down
    change_column_default(:projects, :auto_cancel_pending_pipelines, 0)
  end
end
