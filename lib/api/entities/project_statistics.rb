# frozen_string_literal: true

module API
  module Entities
    class ProjectStatistics < Grape::Entity
      expose :commit_count
      expose :storage_size
      expose :repository_size
      expose :wiki_size
      expose :lfs_objects_size
      expose :build_artifacts_size, as: :job_artifacts_size
      expose :pipeline_artifacts_size
      expose :packages_size
      expose :snippets_size
      expose :uploads_size
      expose :container_registry_size
    end
  end
end
