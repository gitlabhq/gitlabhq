module Geo
  class FileRegistryRemovalService < FileService
    include ::Gitlab::Utils::StrongMemoize

    LEASE_TIMEOUT = 8.hours.freeze

    def execute
      log_info('Executing')

      try_obtain_lease do
        log_info('Lease obtained')

        unless file_registry
          log_error('Could not find file_registry')
          break
        end

        if File.exist?(file_path)
          log_info('Unlinking file', file_path: file_path)
          File.unlink(file_path)
        end

        log_info('Removing file registry', file_registry_id: file_registry.id)
        file_registry.destroy

        log_info('Local file & registry removed')
      end
    rescue SystemCallError
      log_error('Could not remove file', e.message)
      raise
    end

    private

    def file_registry
      strong_memoize(:file_registry) do
        if object_type.to_sym == :job_artifact
          ::Geo::JobArtifactRegistry.find_by(artifact_id: object_db_id)
        else
          ::Geo::FileRegistry.find_by(file_type: object_type, file_id: object_db_id)
        end
      end
    end

    def file_path
      strong_memoize(:file_path) do
        # When local storage is used, just rely on the existing methods
        next file_uploader.file.path if file_uploader.object_store == ObjectStorage::Store::LOCAL

        # For remote storage more juggling is needed to actually get the full path on disk
        if upload?
          upload = file_uploader.upload
          file_uploader.class.absolute_path(upload)
        else
          file_uploader.class.absolute_path(file_uploader.file)
        end
      end
    end

    def file_uploader
      strong_memoize(:file_uploader) do
        case object_type.to_s
        when 'lfs'
          LfsObject.find_by!(id: object_db_id).file
        when 'job_artifact'
          Ci::JobArtifact.find_by!(id: object_db_id).file
        when *Geo::FileService::DEFAULT_OBJECT_TYPES
          Upload.find_by!(id: object_db_id).build_uploader
        else
          raise NameError, "Unrecognized type: #{object_type}"
        end
      end
    rescue NameError, ActiveRecord::RecordNotFound => err
      log_error('Could not build uploader', err.message)
      raise
    end

    def upload?
      Geo::FileService::DEFAULT_OBJECT_TYPES.include?(object_type.to_s)
    end

    def lease_key
      "file_registry_removal_service:#{object_type}:#{object_db_id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
