# frozen_string_literal: true

module Pages
  class DeploymentUploader < GitlabUploader
    include ObjectStorage::Concern

    storage_location :pages

    alias_method :upload, :model

    private

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
