class CleanupFillFileStoreBackgroundMigrations < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class JobArtifact < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_job_artifacts'
  end

  class LfsObject < ActiveRecord::Base
    include EachBatch
    self.table_name = 'lfs_objects'
  end

  class Upload < ActiveRecord::Base
    include EachBatch
    self.table_name = 'uploads'
    self.inheritance_column = :_type_disabled # Disable STI
  end

  def up
    Gitlab::BackgroundMigration.steal('FillFileStoreJobArtifact')
    Gitlab::BackgroundMigration.steal('FillFileStoreLfsObject')
    Gitlab::BackgroundMigration.steal('FillStoreUpload')

    CleanupFillFileStoreBackgroundMigrations::JobArtifact.where(file_store: nil).each_batch(of: 10_000) do |relation|
      start_id, end_id = relation.pluck('MIN(id), MAX(id)').first

      Gitlab::BackgroundMigration::FillFileStoreJobArtifact.new.perform(start_id, end_id)
    end

    CleanupFillFileStoreBackgroundMigrations::LfsObject.where(file_store: nil).each_batch(of: 10_000) do |relation|
      start_id, end_id = relation.pluck('MIN(id), MAX(id)').first

      Gitlab::BackgroundMigration::FillFileStoreLfsObject.new.perform(start_id, end_id)
    end

    CleanupFillFileStoreBackgroundMigrations::Upload.where(store: nil).each_batch(of: 10_000) do |relation|
      start_id, end_id = relation.pluck('MIN(id), MAX(id)').first

      Gitlab::BackgroundMigration::FillStoreUpload.new.perform(start_id, end_id)
    end
  end

  def down
    # no-op
  end
end
