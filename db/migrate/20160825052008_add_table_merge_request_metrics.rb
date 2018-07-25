# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
# rubocop:disable Migration/Timestamps
class AddTableMergeRequestMetrics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = true

  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  DOWNTIME_REASON = 'Adding foreign key'

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
    create_table :merge_request_metrics do |t|
      t.references :merge_request, index: { name: "index_merge_request_metrics" }, foreign_key: { on_delete: :cascade }, null: false

      t.datetime 'latest_build_started_at'
      t.datetime 'latest_build_finished_at'
      t.datetime 'first_deployed_to_production_at', index: true
      t.datetime 'merged_at'

      t.timestamps null: false
    end
  end
end
