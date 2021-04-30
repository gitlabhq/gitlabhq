# frozen_string_literal: true

class UploadChecksumWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :geo_replication

  def perform(upload_id)
    upload = Upload.find(upload_id)
    upload.calculate_checksum!
    upload.save!
  rescue ActiveRecord::RecordNotFound
    Gitlab::AppLogger.error("UploadChecksumWorker: couldn't find upload #{upload_id}, skipping")
  end
end
