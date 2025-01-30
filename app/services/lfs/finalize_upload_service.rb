# frozen_string_literal: true

module Lfs
  class FinalizeUploadService
    def initialize(oid:, size:, uploaded_file:, project:)
      @oid = oid
      @size = size
      @uploaded_file = uploaded_file
      @project = project
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

    attr_reader :oid, :size, :uploaded_file, :project

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

      link_to_project!(object)
    end

    def create_file!
      LfsObject.create!(oid: oid, size: size, file: uploaded_file)
    end

    def replace_file!(lfs_object)
      Gitlab::AppJsonLogger.info(message: "LFS file replaced because it did not exist", oid: oid, size: size)
      lfs_object.file = uploaded_file
      lfs_object.save!
    end

    def link_to_project!(object)
      LfsObjectsProject.safe_find_or_create_by!( # rubocop:disable Performance/ActiveRecordSubtransactionMethods -- Used in the original controller: https://gitlab.com/gitlab-org/gitlab/-/blob/3841ce47b1d6d4611067ff5b8b86dc9cbf290641/app/controllers/repositories/lfs_storage_controller.rb#L118
        project: project,
        lfs_object: object
      )
    end
  end
end
