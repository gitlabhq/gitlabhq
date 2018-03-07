# rubocop:disable Migration/UpdateLargeTable
# rubocop:disable Migration/UpdateColumnInBatches
class MigrateAssignees < ActiveRecord::Migration
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
    # Optimisation: this accounts for most of the invalid assignee IDs on GitLab.com
    update_column_in_batches(:issues, :assignee_id, nil) do |table, query|
      query.where(table[:assignee_id].eq(0))
    end

    users = Arel::Table.new(:users)

    update_column_in_batches(:issues, :assignee_id, nil) do |table, query|
      query.where(table[:assignee_id].not_eq(nil)\
        .and(
          users.project("true").where(users[:id].eq(table[:assignee_id])).exists.not
        ))
    end
  end

  def down
  end
end
