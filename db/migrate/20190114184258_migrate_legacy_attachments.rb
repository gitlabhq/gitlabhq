# frozen_string_literal: true

class MigrateLegacyAttachments < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  MIGRATION = 'MigrateLegacyUploads'.freeze
  BATCH_SIZE = 5000
  DELAY_INTERVAL = 5.minutes.to_i

  class Upload < ActiveRecord::Base
    self.table_name = 'uploads'

    include ::EachBatch
  end

  def up
    Upload.where(uploader: 'AttachmentUploader').each_batch(of: BATCH_SIZE) do |relation, index|
      start_id, end_id = relation.pluck('MIN(id), MAX(id)').first
      delay = index * DELAY_INTERVAL

      BackgroundMigrationWorker.perform_in(delay, MIGRATION, [start_id, end_id])
    end
  end

  # not needed
  def down
  end
end
