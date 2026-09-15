# frozen_string_literal: true

class AddFksToAiSuggestedReviewers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  def up
    add_concurrent_foreign_key :ai_suggested_reviewers, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :ai_suggested_reviewers, :merge_requests, column: :merge_request_id, on_delete: :cascade
    add_concurrent_foreign_key :ai_suggested_reviewers, :users, column: :user_id, on_delete: :cascade
    add_concurrent_foreign_key :ai_suggested_reviewers, :approval_merge_request_rules,
      column: :approval_merge_request_rule_id, on_delete: :cascade
    add_concurrent_foreign_key :ai_suggested_reviewers, :approval_project_rules,
      column: :approval_project_rule_id, on_delete: :cascade

    add_multi_column_not_null_constraint(:ai_suggested_reviewers, :approval_merge_request_rule_id,
      :approval_project_rule_id, limit: 1, operator: '<=')
  end

  def down
    remove_multi_column_not_null_constraint(:ai_suggested_reviewers, :approval_merge_request_rule_id,
      :approval_project_rule_id)

    with_lock_retries do
      remove_foreign_key_if_exists :ai_suggested_reviewers, column: :approval_project_rule_id
      remove_foreign_key_if_exists :ai_suggested_reviewers, column: :approval_merge_request_rule_id
      remove_foreign_key_if_exists :ai_suggested_reviewers, column: :user_id
      remove_foreign_key_if_exists :ai_suggested_reviewers, column: :merge_request_id
      remove_foreign_key_if_exists :ai_suggested_reviewers, column: :project_id
    end
  end
end
