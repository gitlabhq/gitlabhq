# rubocop:disable Migration/UpdateLargeTable
# rubocop:disable Migration/UpdateColumnInBatches
class ResetRelativePositionForIssue < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:issues, :relative_position, nil) do |table, query|
      query.where(table[:relative_position].not_eq(nil))
    end
  end

  def down
    # noop
  end
end
