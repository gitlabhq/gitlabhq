# frozen_string_literal: true

class AddProjectIdToMergeRequestReviewLlmSummaries < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :merge_request_review_llm_summaries, :project_id, :bigint
  end
end
