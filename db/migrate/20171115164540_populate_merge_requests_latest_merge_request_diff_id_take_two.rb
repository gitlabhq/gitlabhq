# This is identical to the stolen background migration, which already has specs.
class PopulateMergeRequestsLatestMergeRequestDiffIdTakeTwo < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1_000

  class MergeRequest < ActiveRecord::Base
    self.table_name = 'merge_requests'

    include ::EachBatch
  end

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal('PopulateMergeRequestsLatestMergeRequestDiffId')

    update = '
      latest_merge_request_diff_id = (
        SELECT MAX(id)
        FROM merge_request_diffs
        WHERE merge_requests.id = merge_request_diffs.merge_request_id
      )'.squish

    MergeRequest.where(latest_merge_request_diff_id: nil).each_batch(of: BATCH_SIZE) do |relation|
      relation.update_all(update)
    end
  end
end
