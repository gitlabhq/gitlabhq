# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddForeignKeysToTimelogs < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  DOWNTIME_REASON = ''

  # When using the methods "add_concurrent_index" or "add_column_with_default"
  # you must disable the use of transactions as these methods can not run in an
  # existing transaction. When using "add_concurrent_index" make sure that this
  # method is the _only_ method called in the migration, any other changes
  # should go in a separate migration. This ensures that upon failure _only_ the
  # index creation fails and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  disable_ddl_transaction!

  def up
    change_table :timelogs do |t|
      t.column :issue_id, :integer
      t.column :merge_request_id, :integer
    end

    add_concurrent_index :timelogs, :issue_id
    add_concurrent_index :timelogs, :merge_request_id

    if Gitlab::Database.postgresql?
      execute <<-EOF
        ALTER TABLE timelogs ADD CONSTRAINT "fk_timelogs_issues_issue_id" FOREIGN KEY (issue_id) REFERENCES "issues" (id) ON DELETE CASCADE NOT VALID;
        ALTER TABLE timelogs ADD CONSTRAINT "fk_timelogs_merge_requests_merge_request_id" FOREIGN KEY (merge_request_id) REFERENCES "merge_requests" (id) ON DELETE CASCADE NOT VALID;
      EOF
    else
      execute "ALTER TABLE timelogs ADD CONSTRAINT fk_timelogs_issues_issue_id FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE;"
      execute "ALTER TABLE timelogs ADD CONSTRAINT fk_timelogs_merge_requests_merge_request_id FOREIGN KEY (merge_request_id) REFERENCES merge_requests(id) ON DELETE CASCADE;"
    end

    Timelog.where(trackable_type: 'Issue').update_all("issue_id = trackable_id")
    Timelog.where(trackable_type: 'MergeRequest').update_all("merge_request_id = trackable_id")
  end

  def down
    Timelog.where('issue_id IS NOT NULL').update_all("trackable_id = issue_id, trackable_type = 'Issue'")
    Timelog.where('merge_request_id IS NOT NULL').update_all("trackable_id = merge_request_id, trackable_type = 'MergeRequest'")

    remove_foreign_key :timelogs, name: 'fk_timelogs_issues_issue_id'
    remove_foreign_key :timelogs, name: 'fk_timelogs_merge_requests_merge_request_id'

    remove_columns :timelogs, :issue_id, :merge_request_id
  end
end
