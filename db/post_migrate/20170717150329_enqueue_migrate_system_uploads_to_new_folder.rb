class EnqueueMigrateSystemUploadsToNewFolder < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  OLD_FOLDER = 'uploads/system/'
  NEW_FOLDER = 'uploads/-/system/'

  disable_ddl_transaction!

  def up
    BackgroundMigrationWorker.perform_async('MigrateSystemUploadsToNewFolder',
                                            [OLD_FOLDER, NEW_FOLDER])
  end

  def down
    BackgroundMigrationWorker.perform_async('MigrateSystemUploadsToNewFolder',
                                            [NEW_FOLDER, OLD_FOLDER])
  end
end
