# frozen_string_literal: true

class MigrateLegacyAttachments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  MIGRATION = 'LegacyUploadsMigrator'
  BATCH_SIZE = 5000
  INTERVAL = 5.minutes.to_i

  class Upload < ActiveRecord::Base
    self.table_name = 'uploads'

    include ::EachBatch
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(Upload.where(uploader: 'AttachmentUploader', model_type: 'Note'),
                                                          MIGRATION,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end
