class RequeuePendingDelete < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

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
    admin = User.find_by(admin: true)

    Group.with_deleted.where.not(deleted_at: nil).find_each do |group|
      GroupDestroyWorker.perform_async(group.id, admin.id)
    end

    Project.unscoped.where(pending_delete: true).find_each do |project|
      ProjectDestroyWorker.perform_async(project.id, admin.id)
    end
  end

  def down
    # Noop
  end
end
