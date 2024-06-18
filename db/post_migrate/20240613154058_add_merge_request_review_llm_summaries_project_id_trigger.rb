# frozen_string_literal: true

class AddMergeRequestReviewLlmSummariesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    install_sharding_key_assignment_trigger(
      table: :merge_request_review_llm_summaries,
      sharding_key: :project_id,
      parent_table: :reviews,
      parent_sharding_key: :project_id,
      foreign_key: :review_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :merge_request_review_llm_summaries,
      sharding_key: :project_id,
      parent_table: :reviews,
      parent_sharding_key: :project_id,
      foreign_key: :review_id
    )
  end
end
