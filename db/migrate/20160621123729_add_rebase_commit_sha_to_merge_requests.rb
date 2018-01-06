<<<<<<< HEAD
# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRebaseCommitShaToMergeRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # When using the methods "add_concurrent_index" or "add_column_with_default"
  # you must disable the use of transactions as these methods can not run in an
  # existing transaction. When using "add_concurrent_index" make sure that this
  # method is the _only_ method called in the migration, any other changes
  # should go in a separate migration. This ensures that upon failure _only_ the
  # index creation fails and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  # disable_ddl_transaction!

  def change
    add_column :merge_requests, :rebase_commit_sha, :string
=======
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
>>>>>>> upstream/master
  end
end
