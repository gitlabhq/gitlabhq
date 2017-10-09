# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class AddPipelineIdToMergeRequestMetrics < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = true

  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  DOWNTIME_REASON = 'Adding a foreign key'

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
    add_column :merge_request_metrics, :pipeline_id, :integer
    add_foreign_key :merge_request_metrics, :ci_commits, column: :pipeline_id, on_delete: :cascade # rubocop: disable Migration/AddConcurrentForeignKey
    add_concurrent_index :merge_request_metrics, :pipeline_id
  end

  def down
    remove_foreign_key :merge_request_metrics, column: :pipeline_id
    remove_index :merge_request_metrics, :pipeline_id if index_exists? :merge_request_metrics, :pipeline_id
    remove_column :merge_request_metrics, :pipeline_id
  end
end
