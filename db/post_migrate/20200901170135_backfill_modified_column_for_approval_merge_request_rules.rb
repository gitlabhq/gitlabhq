# frozen_string_literal: true

class BackfillModifiedColumnForApprovalMergeRequestRules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::Migrations::BackgroundMigrationHelpers

  disable_ddl_transaction!

  class ApprovalMergeRequestRule < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'approval_merge_request_rules'
  end

  def change
    queue_background_migration_jobs_by_range_at_intervals(ApprovalMergeRequestRule, 'AddModifiedToApprovalMergeRequestRule', 2.minutes, batch_size: 10_000)
  end
end
