# frozen_string_literal: true

class DropUnusedFieldsFromMergeRequestReviewers < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      if column_exists?(:merge_request_reviewers, :updated_state_by_user_id)
        remove_column :merge_request_reviewers, :updated_state_by_user_id
      end
    end
  end

  def down
    with_lock_retries do
      unless column_exists?(:merge_request_reviewers, :updated_state_by_user_id)
        add_column :merge_request_reviewers, :updated_state_by_user_id, :bigint
      end
    end

    add_concurrent_index :merge_request_reviewers, :updated_state_by_user_id,
      name: 'index_on_merge_request_reviewers_updated_state_by_user_id'

    add_concurrent_foreign_key :merge_request_reviewers, :users, column: :updated_state_by_user_id, on_delete: :nullify
  end
end
