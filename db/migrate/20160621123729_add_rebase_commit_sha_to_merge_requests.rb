# This migration is a duplicate of 20171230123729_add_rebase_commit_sha_to_merge_requests_ce.rb
#
# We backported this feature from EE using the same migration, but with a new
# timestamp, which caused an error when the backport was then to be merged back
# into EE.
#
# See discussion at https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3932
class AddRebaseCommitShaToMergeRequests < ActiveRecord::Migration
  DOWNTIME = false

  def up
    unless column_exists?(:merge_requests, :rebase_commit_sha)
      add_column :merge_requests, :rebase_commit_sha, :string
    end
  end

  def down
    if column_exists?(:merge_requests, :rebase_commit_sha)
      remove_column :merge_requests, :rebase_commit_sha
    end
  end
end
