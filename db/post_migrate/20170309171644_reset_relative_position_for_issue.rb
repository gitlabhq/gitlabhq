# rubocop:disable Migration/UpdateColumnInBatches
class ResetRelativePositionForIssue < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    update_column_in_batches(:issues, :relative_position, nil) do |table, query|
      query.where(table[:relative_position].not_eq(nil))
    end
  end

  def down
  end
end
