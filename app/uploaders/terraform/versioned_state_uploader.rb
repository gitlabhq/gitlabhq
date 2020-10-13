# frozen_string_literal: true

module Terraform
  class VersionedStateUploader < StateUploader
    delegate :terraform_state, to: :model

    def filename
      if terraform_state.versioning_enabled?
        "#{model.version}.tfstate"
      else
        "#{model.uuid}.tfstate"
      end
    end

    def store_dir
      if terraform_state.versioning_enabled?
        Gitlab::HashedPath.new(model.uuid, root_hash: project_id)
      else
        project_id.to_s
      end
    end
  end
end
