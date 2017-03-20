# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAutoCanceledByIdToPipeline < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  # DOWNTIME_REASON = ''

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
    on_delete =
      if Database.mysql?
        :nullify
      else
        'SET NULL'
      end

    add_column :ci_pipelines, :auto_canceled_by_id, :integer
    add_concurrent_foreign_key :ci_pipelines, :ci_pipelines, column: :auto_canceled_by_id, on_delete: on_delete
  end

  def down
    remove_foreign_key :ci_pipelines, column: :auto_canceled_by_id
    remove_column :ci_pipelines, :auto_canceled_by_id
  end
end
