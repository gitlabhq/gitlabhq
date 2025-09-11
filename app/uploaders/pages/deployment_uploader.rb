# frozen_string_literal: true

module Pages
  class DeploymentUploader < GitlabUploader
    include ObjectStorage::Concern

    storage_location :pages

    alias_method :upload, :model

    def filename
      trim_filename_if_needed(super)
    end

    private

    # Trims filename to 60 characters from the front if it exceeds that length
    def trim_filename_if_needed(filename)
      return if filename.nil?
      return filename if filename.length <= 60

      # Take the last 60 characters
      filename[-60..]
    end

    def dynamic_segment
      Gitlab::HashedPath.new('pages_deployments', model.id, root_hash: model.project_id)
    end

    # @hashed is chosen to avoid conflict with namespace name because we use the same directory for storage
    # @ is not valid character for namespace
    def base_dir
      "@hashed"
    end

    # override GitlabUploader
    # if set to true it erases the original file when uploading
    # and we copy from the artifacts archive, so artifacts end up
    # without the file
    def move_to_cache
      false
    end

    class << self
      # we only upload this files from the rails background job
      # so we don't need direct upload for pages deployments
      # this method is here to ignore any user setting
      def direct_upload_enabled?
        false
      end

      def default_store
        object_store_enabled? ? ObjectStorage::Store::REMOTE : ObjectStorage::Store::LOCAL
      end
    end
  end
end

Pages::DeploymentUploader.prepend_mod
