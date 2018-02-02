class UploadChecksumWorker
  include ApplicationWorker

  def perform(upload_id)
    upload = Upload.find(upload_id)
    upload.calculate_checksum!
    upload.save!
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("UploadChecksumWorker: couldn't find upload #{upload_id}, skipping")
  end
end
