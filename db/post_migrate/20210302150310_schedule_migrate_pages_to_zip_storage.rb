# frozen_string_literal: true

class ScheduleMigratePagesToZipStorage < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'MigratePagesToZipStorage'
  BATCH_SIZE = 10
  BATCH_TIME = 5.minutes

  disable_ddl_transaction!

  class ProjectPagesMetadatum < ActiveRecord::Base
    extend SuppressCompositePrimaryKeyWarning

    include EachBatch

    self.primary_key = :project_id
    self.table_name = 'project_pages_metadata'
    self.inheritance_column = :_type_disabled

    scope :deployed, -> { where(deployed: true) }
    scope :only_on_legacy_storage, -> { deployed.where(pages_deployment_id: nil) }
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      ProjectPagesMetadatum.only_on_legacy_storage,
      MIGRATION,
      BATCH_TIME,
      batch_size: BATCH_SIZE,
      primary_column_name: :project_id
    )
  end
end
