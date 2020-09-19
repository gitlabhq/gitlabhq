# frozen_string_literal: true

module Terraform
  class VersionedStateUploader < StateUploader
    def filename
      "#{model.version}.tfstate"
    end

    def store_dir
      Gitlab::HashedPath.new(model.uuid, root_hash: project_id)
    end
  end
end
