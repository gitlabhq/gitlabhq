module Geo
  class FileDownloadService < FileService
    LEASE_TIMEOUT = 8.hours.freeze

    include Delay

    def execute
      try_obtain_lease do |lease|
        start_time = Time.now
        bytes_downloaded = downloader.execute
        success = (bytes_downloaded.present? && bytes_downloaded >= 0)
        log_info("File download",
                 success: success,
                 bytes_downloaded: bytes_downloaded,
                 download_time_s: (Time.now - start_time).to_f.round(3))
        update_registry(bytes_downloaded, success: success)
      end
    end

    private

    def downloader
      klass = "Gitlab::Geo::#{service_klass_name}Downloader".constantize
      klass.new(object_type, object_db_id)
    rescue NameError => e
      log_error('Unknown file type', e)
      raise
    end

    def try_obtain_lease
      uuid = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT).try_obtain

      return unless uuid.present?

      begin
        yield
      ensure
        Gitlab::ExclusiveLease.cancel(lease_key, uuid)
      end
    end

    def update_registry(bytes_downloaded, success:)
      transfer = Geo::FileRegistry.find_or_initialize_by(
        file_type: object_type,
        file_id: object_db_id
      )

      transfer.bytes = bytes_downloaded
      transfer.success = success

      unless success
        # We don't limit the amount of retries
        transfer.retry_count = (transfer.retry_count || 0) + 1
        transfer.retry_at = Time.now + delay(transfer.retry_count).seconds
      end

      transfer.save
    end

    def lease_key
      "file_download_service:#{object_type}:#{object_db_id}"
    end
  end
end
