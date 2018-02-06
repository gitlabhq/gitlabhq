# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddColumnInProgressMergeCommitShaToMergeRequests < ActiveRecord::Migration
  def change
    add_column :merge_requests, :in_progress_merge_commit_sha, :string
  end
end
