# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMergeRequestContextCommitTrailers < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :merge_request_context_commits, :trailers, :jsonb, default: {}, null: false
  end
end
