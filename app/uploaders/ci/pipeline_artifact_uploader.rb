# frozen_string_literal: true

module Ci
  class PipelineArtifactUploader < GitlabUploader
    include ObjectStorage::Concern

    storage_location :artifacts

    alias_method :upload, :model

    def store_dir
      dynamic_segment
    end

    private

    def dynamic_segment
      Gitlab::HashedPath.new('pipelines', model.pipeline_id, 'artifacts', model.id, root_hash: model.project_id)
    end
  end
end
