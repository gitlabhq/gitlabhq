# frozen_string_literal: true

class AddProjectIdToMergeRequestReviewers < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :merge_request_reviewers, :project_id, :bigint
  end
end
