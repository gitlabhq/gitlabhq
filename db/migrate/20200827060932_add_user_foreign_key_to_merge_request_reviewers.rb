# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddUserForeignKeyToMergeRequestReviewers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :merge_request_reviewers, :users, column: :user_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_request_reviewers, column: :user_id
    end
  end
end
