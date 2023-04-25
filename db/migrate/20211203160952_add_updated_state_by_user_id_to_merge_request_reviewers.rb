# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddUpdatedStateByUserIdToMergeRequestReviewers < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :merge_request_reviewers, :updated_state_by_user_id, :bigint
  end
end
