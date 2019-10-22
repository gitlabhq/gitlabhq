# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateRemainingAnyApproverRulesForMergeRequests < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000
  MIGRATION = 'PopulateAnyApprovalRuleForMergeRequests'

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'

    scope :with_approvals_before_merge, -> { where.not(approvals_before_merge: 0) }
  end

  def up
    return unless Gitlab.ee?

    add_concurrent_index :merge_requests, :id,
      name: 'tmp_merge_requests_with_approvals_before_merge',
      where: 'approvals_before_merge != 0'

    Gitlab::BackgroundMigration.steal(MIGRATION)

    PopulateRemainingAnyApproverRulesForMergeRequests::MergeRequest.with_approvals_before_merge.each_batch(of: BATCH_SIZE) do |batch|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      Gitlab::BackgroundMigration::PopulateAnyApprovalRuleForMergeRequests.new.perform(*range)
    end

    remove_concurrent_index_by_name(:merge_requests, 'tmp_merge_requests_with_approvals_before_merge')
  end

  def down
    # no-op
  end
end
