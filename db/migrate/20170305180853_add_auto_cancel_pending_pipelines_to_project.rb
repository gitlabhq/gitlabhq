# rubocop:disable Migration/UpdateLargeTable
class AddAutoCancelPendingPipelinesToProject < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:projects, :auto_cancel_pending_pipelines, :integer, default: 0)
  end

  def down
    remove_column(:projects, :auto_cancel_pending_pipelines)
  end
end
