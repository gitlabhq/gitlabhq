class MigrateStageIdReferenceInBackground < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    self.table_name = 'ci_builds'
  end

  def up
    Build.find_each do |build|
      BackgroundMigrationWorker
        .perform_async('MigrateBuildStageIdReference', [build.id])
    end
  end

  def down
    # noop
  end
end
