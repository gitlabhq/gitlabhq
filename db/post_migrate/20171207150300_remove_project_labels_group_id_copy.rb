# Copy of 20180202111106 - this one should run before 20171207150343 to fix issues related to
# the removal of groups with labels.

class RemoveProjectLabelsGroupIdCopy < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/UpdateColumnInBatches
    update_column_in_batches(:labels, :group_id, nil) do |table, query|
      query.where(table[:type].eq('ProjectLabel').and(table[:group_id].not_eq(nil)))
    end
    # rubocop:enable Migration/UpdateColumnInBatches
  end

  def down
  end
end
