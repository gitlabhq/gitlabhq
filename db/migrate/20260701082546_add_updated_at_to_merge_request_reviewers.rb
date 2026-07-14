# frozen_string_literal: true

class AddUpdatedAtToMergeRequestReviewers < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :merge_request_reviewers, :updated_at, :datetime_with_timezone
  end
end
