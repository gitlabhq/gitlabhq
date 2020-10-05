# frozen_string_literal: true

module Pages
  class DeploymentUploader < GitlabUploader
    include ObjectStorage::Concern

    storage_options Gitlab.config.pages

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
  end
end
