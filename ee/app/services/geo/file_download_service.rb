module Geo
  # This class is responsible for:
  #   * Finding the appropriate Downloader class for a FileRegistry record
  #   * Executing the Downloader
  #   * Marking the FileRegistry record as synced or needing retry
  class FileDownloadService < FileService
    LEASE_TIMEOUT = 8.hours.freeze

    include Delay
    include ExclusiveLeaseGuard

    def execute
      try_obtain_lease do
        start_time = Time.now

        download_result = downloader.execute

        mark_as_synced = download_result.success || download_result.primary_missing_file

        log_file_download(mark_as_synced, download_result, start_time)
        update_registry(download_result.bytes_downloaded,
                        mark_as_synced: mark_as_synced,
                        missing_on_primary: download_result.primary_missing_file)
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

    def log_file_download(mark_as_synced, download_result, start_time)
      metadata = {
        mark_as_synced: mark_as_synced,
        download_success: download_result.success,
        bytes_downloaded: download_result.bytes_downloaded,
        failed_before_transfer: download_result.failed_before_transfer,
        primary_missing_file: download_result.primary_missing_file,
        download_time_s: (Time.now - start_time).to_f.round(3)
      }

      log_info("File download", metadata)
    end

    def update_registry(bytes_downloaded, mark_as_synced:, missing_on_primary: false)
      registry =
        if object_type.to_sym == :job_artifact
          Geo::JobArtifactRegistry.find_or_initialize_by(artifact_id: object_db_id)
        else
          Geo::FileRegistry.find_or_initialize_by(
            file_type: object_type,
            file_id: object_db_id
          )
        end

      registry.bytes = bytes_downloaded
      registry.success = mark_as_synced
      registry.missing_on_primary = missing_on_primary

      unless mark_as_synced
        # We don't limit the amount of retries
        registry.retry_count = (registry.retry_count || 0) + 1
        registry.retry_at = Time.now + delay(registry.retry_count).seconds
      end

      registry.save
    end

    def lease_key
      "file_download_service:#{object_type}:#{object_db_id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
