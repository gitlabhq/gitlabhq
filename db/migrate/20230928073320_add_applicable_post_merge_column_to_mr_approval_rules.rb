# frozen_string_literal: true

class AddApplicablePostMergeColumnToMrApprovalRules < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :approval_merge_request_rules, :applicable_post_merge, :boolean
  end
end
