# frozen_string_literal: true

class AddMergeRequestDiffCommitUserColumns < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    # NOTE: these columns are _not_ indexed, nor do they use foreign keys.
    #
    # This is deliberate, as creating these indexes on GitLab.com takes a _very_
    # long time. In addition, there's no real need for them either based on how
    # this data is used.
    #
    # For more information, refer to the following:
    #
    # - https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5038#note_614592881
    # - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63669
    add_column(:merge_request_diff_commits, :commit_author_id, :bigint)
    add_column(:merge_request_diff_commits, :committer_id, :bigint)
  end

  def down
    remove_column(:merge_request_diff_commits, :commit_author_id)
    remove_column(:merge_request_diff_commits, :committer_id)
  end
end
