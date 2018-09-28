class MigrateObjectStorageUploadSidekiqQueue < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    sidekiq_queue_migrate 'object_storage_upload', to: 'object_storage:object_storage_background_move'
  end

  def down
    # do not migrate any jobs back because we would migrate also
    # jobs which were not part of the 'object_storage_upload'
  end
end
