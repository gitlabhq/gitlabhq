# frozen_string_literal: true

namespace :gitlab do
  namespace :uploads do
    namespace :legacy do
      desc "GitLab | Uploads | Migrate all legacy attachments"
      task migrate: :environment do
        class Upload < ApplicationRecord
          self.table_name = 'uploads'

          include ::EachBatch
        end

        migration = 'LegacyUploadsMigrator'.freeze
        batch_size = 5000
        delay_interval = 5.minutes.to_i

        Upload.where(uploader: 'AttachmentUploader').each_batch(of: batch_size) do |relation, index|
          start_id, end_id = relation.pluck('MIN(id), MAX(id)').first
          delay = index * delay_interval

          BackgroundMigrationWorker.perform_in(delay, migration, [start_id, end_id])
        end
      end
    end
  end
end
