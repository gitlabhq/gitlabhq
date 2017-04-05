module Geo
  class FileDownloadService
    attr_reader :object_type, :object_db_id

    LEASE_TIMEOUT = 8.hours.freeze
    DEFAULT_OBJECT_TYPES = [:attachment, :avatar, :file].freeze

    def initialize(object_type, object_db_id)
      @object_type = object_type
      @object_db_id = object_db_id
    end

    def execute
      try_obtain_lease do |lease|
        bytes_downloaded = downloader.execute
        success = bytes_downloaded && bytes_downloaded >= 0
        update_registry(bytes_downloaded) if success
      end
    end

    private

    def downloader
      klass = downloader_klass_name.constantize
      klass.new(object_type, object_db_id)
    rescue NameError
      log("Unknown file type: #{object_type}")
      raise
    end

    def downloader_klass_name
      klass_name =
        if DEFAULT_OBJECT_TYPES.include?(object_type.to_sym)
          :file
        else
          object_type
        end

      "Gitlab::Geo::#{klass_name.to_s.camelize}Downloader"
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

    def update_registry(bytes_downloaded)
      transfer = Geo::FileRegistry.find_or_initialize_by(
        file_type: object_type,
        file_id: object_db_id
      )

      transfer.bytes = bytes_downloaded
      transfer.save
    end

    def lease_key
      "file_download_service:#{object_type}:#{object_db_id}"
    end

    def log(message)
      Rails.logger.info "#{self.class.name}: #{message}"
    end
  end
end
