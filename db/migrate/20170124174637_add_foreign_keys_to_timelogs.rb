# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddForeignKeysToTimelogs < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = true
  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  DOWNTIME_REASON = 'Adding foreign keys'

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

  def up
    change_table :timelogs do |t|
      t.references :issue, index: true, foreign_key: { on_delete: :cascade }
      t.references :merge_request, index: true, foreign_key: { on_delete: :cascade }
    end

    Timelog.where(trackable_type: 'Issue').update_all("issue_id = trackable_id")
    Timelog.where(trackable_type: 'MergeRequest').update_all("merge_request_id = trackable_id")

    remove_columns :timelogs, :trackable_id, :trackable_type
  end

  def down
    add_reference :timelogs, :trackable, polymorphic: true, index: true

    Timelog.where('issue_id IS NOT NULL').update_all("trackable_id = issue_id, trackable_type = 'Issue'")
    Timelog.where('merge_request_id IS NOT NULL').update_all("trackable_id = merge_request_id, trackable_type = 'MergeRequest'")

    remove_columns :timelogs, :issue_id, :merge_request_id
  end
end
