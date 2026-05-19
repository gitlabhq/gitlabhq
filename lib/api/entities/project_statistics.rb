# frozen_string_literal: true

module API
  module Entities
    class ProjectStatistics < Grape::Entity
      expose :commit_count, documentation: { type: 'Integer', example: 37 }
      expose :storage_size, documentation: { type: 'Integer', example: 1038090 }
      expose :repository_size, documentation: { type: 'Integer', example: 1038090 }
      expose :wiki_size, documentation: { type: 'Integer', example: 0 }
      expose :lfs_objects_size, documentation: { type: 'Integer', example: 0 }
      expose :build_artifacts_size, as: :job_artifacts_size, documentation: { type: 'Integer', example: 0 }
      expose :pipeline_artifacts_size, documentation: { type: 'Integer', example: 0 }
      expose :packages_size, documentation: { type: 'Integer', example: 0 }
      expose :snippets_size, documentation: { type: 'Integer', example: 0 }
      expose :uploads_size, documentation: { type: 'Integer', example: 0 }
      expose :container_registry_size, documentation: { type: 'Integer', example: 0 }
    end
  end
end
