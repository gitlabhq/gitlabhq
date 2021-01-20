# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMergeRequestDiffCommitTrailers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :merge_request_diff_commits, :trailers, :jsonb, default: {}, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :merge_request_diff_commits, :trailers
    end
  end
end
