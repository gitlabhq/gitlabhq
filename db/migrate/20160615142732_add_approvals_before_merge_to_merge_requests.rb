class AddApprovalsBeforeMergeToMergeRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :merge_requests, :approvals_before_merge, :integer
  end
end
