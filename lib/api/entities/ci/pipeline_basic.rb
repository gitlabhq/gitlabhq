# frozen_string_literal: true

module API
  module Entities
    module Ci
      class PipelineBasic < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :iid, documentation: { type: 'Integer', example: 2 }
        expose :project_id, documentation: { type: 'Integer', example: 3 }
        expose :sha, documentation: { type: 'String', example: '0ec9e58fdfca6cdd6652c083c9edb53abc0bad52' }
        expose :ref, documentation: { type: 'String', example: 'feature-branch' }
        expose :status, documentation: { type: 'String', example: 'success' }
        expose :source, documentation: { type: 'String', example: 'push' }
        expose :created_at, documentation: { type: 'DateTime', example: '2022-10-21T16:49:48.000+02:00' }
        expose :updated_at, documentation: { type: 'DateTime', example: '2022-10-21T16:49:48.000+02:00' }

        expose :web_url,
          documentation: {
            type: 'String',
            example: 'https://gitlab.example.com/gitlab-org/gitlab-foss/-/pipelines/61'
          } do |pipeline, _options|
          Gitlab::Routing.url_helpers.project_pipeline_url(pipeline.project, pipeline)
        end
      end
    end
  end
end
