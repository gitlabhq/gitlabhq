# rubocop:disable Migration/UpdateLargeTable
# rubocop:disable Migration/UpdateColumnInBatches
class EnableAutoCancelPendingPipelinesForAll < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    disable_statement_timeout do
      update_column_in_batches(:projects, :auto_cancel_pending_pipelines, 1)
    end
  end

  def down
    # Nothing we can do!
  end
end
