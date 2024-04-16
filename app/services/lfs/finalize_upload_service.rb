# frozen_string_literal: true

module Lfs
  class FinalizeUploadService
    InvalidUploadedFile = Class.new(StandardError)

    def initialize(oid:, size:, uploaded_file:, project:)
      @oid = oid
      @size = size
      @uploaded_file = uploaded_file
      @project = project
    end

    def execute
      validate_uploaded_file!

      if store_file!
        ServiceResponse.success
      else
        ServiceResponse.error(reason: :unprocessable_entity, message: 'Unprocessable entity')
      end
    rescue ActiveRecord::RecordInvalid
      ServiceResponse.error(reason: :invalid_record, message: 'Invalid record')
    rescue UploadedFile::InvalidPathError
      ServiceResponse.error(reason: :invalid_path, message: 'Invalid path')
    rescue ObjectStorage::RemoteStoreError
      ServiceResponse.error(reason: :remote_store_error, message: 'Remote store error')
    rescue InvalidUploadedFile
      ServiceResponse.error(reason: :invalid_uploaded_file, message: 'SHA256 or size mismatch')
    end

    private

    attr_reader :oid, :size, :uploaded_file, :project

    def store_file!
      object = LfsObject.for_oid_and_size(oid, size)

      if object
        replace_file!(object) unless object.file&.exists?
      else
        object = create_file!
      end

      return unless object

      link_to_project!(object)
    end

    def create_file!
      return unless uploaded_file.is_a?(UploadedFile)

      LfsObject.create!(oid: oid, size: size, file: uploaded_file)
    end

    def replace_file!(lfs_object)
      raise UploadedFile::InvalidPathError unless uploaded_file.is_a?(UploadedFile)

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

    def validate_uploaded_file!
      return unless uploaded_file

      return unless size != uploaded_file.size || oid != uploaded_file.sha256

      raise InvalidUploadedFile
    end
  end
end
