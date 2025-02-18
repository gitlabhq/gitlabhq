# frozen_string_literal: true

module Lfs
  class FinalizeUploadService
    def initialize(oid:, size:, uploaded_file:, project:, repository_type:)
      @oid = oid
      @size = size
      @uploaded_file = uploaded_file
      @project = project
      @repository_type = repository_type
    end

    def execute
      return service_response_error(:unprocessable_entity, 'Unprocessable entity') unless uploaded_file
      return service_response_error(:invalid_path, 'Invalid path') unless uploaded_file.is_a?(UploadedFile)

      if size != uploaded_file.size || oid != uploaded_file.sha256
        return service_response_error(:invalid_uploaded_file, 'SHA256 or size mismatch')
      end

      ServiceResponse.success if store_file!

    rescue ActiveRecord::RecordInvalid
      service_response_error(:invalid_record, 'Invalid record')
    rescue ObjectStorage::RemoteStoreError
      service_response_error(:remote_store_error, 'Remote store error')
    end

    private

    attr_reader :oid, :size, :uploaded_file, :project, :repository_type

    def service_response_error(reason, message)
      ServiceResponse.error(reason: reason, message: message)
    end

    def store_file!
      object = LfsObject.for_oid_and_size(oid, size)

      if object
        replace_file!(object) unless object.file&.exists?
      else
        object = create_file!
      end

      LfsObjectsProject.link_to_project!(object, project, repository_type)
    end

    def create_file!
      LfsObject.create!(oid: oid, size: size, file: uploaded_file)
    end

    def replace_file!(lfs_object)
      Gitlab::AppJsonLogger.info(message: "LFS file replaced because it did not exist", oid: oid, size: size)
      lfs_object.file = uploaded_file
      lfs_object.save!
    end
  end
end
