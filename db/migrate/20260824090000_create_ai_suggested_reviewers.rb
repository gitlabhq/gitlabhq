# frozen_string_literal: true

class CreateAiSuggestedReviewers < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  UNIQUE_INDEX_NAME = 'index_ai_suggested_reviewers_on_merge_request_id_and_user_id'
  USER_INDEX_NAME = 'index_ai_suggested_reviewers_on_user_id'
  PROJECT_INDEX_NAME = 'index_ai_suggested_reviewers_on_project_id'
  MERGE_REQUEST_RULE_INDEX_NAME = 'index_ai_suggested_reviewers_on_approval_merge_request_rule_id'
  PROJECT_RULE_INDEX_NAME = 'index_ai_suggested_reviewers_on_approval_project_rule_id'

  def change
    create_table :ai_suggested_reviewers do |t|
      t.bigint :project_id, null: false
      t.bigint :merge_request_id, null: false
      t.bigint :user_id, null: false
      t.bigint :approval_merge_request_rule_id
      t.bigint :approval_project_rule_id
      t.timestamps_with_timezone null: false
      t.text :reason, null: true, limit: 2048

      t.index [:merge_request_id, :user_id], unique: true, name: UNIQUE_INDEX_NAME
      t.index :user_id, name: USER_INDEX_NAME
      t.index :project_id, name: PROJECT_INDEX_NAME
      t.index :approval_merge_request_rule_id, name: MERGE_REQUEST_RULE_INDEX_NAME
      t.index :approval_project_rule_id, name: PROJECT_RULE_INDEX_NAME
    end
  end
end
