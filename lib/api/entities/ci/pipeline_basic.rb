# frozen_string_literal: true

module API
  module Entities
    module Ci
      class PipelineBasic < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 1 }
        expose :iid, documentation: { type: 'integer', example: 2 }
        expose :project_id, documentation: { type: 'integer', example: 3 }
        expose :sha, documentation: { type: 'string', example: '0ec9e58fdfca6cdd6652c083c9edb53abc0bad52' }
        expose :ref, documentation: { type: 'string', example: 'feature-branch' }
        expose :status, documentation: { type: 'string', example: 'success' }
        expose :source, documentation: { type: 'string', example: 'push' }
        expose :created_at, documentation: { type: 'dateTime', example: '2022-10-21T16:49:48.000+02:00' }
        expose :updated_at, documentation: { type: 'dateTime', example: '2022-10-21T16:49:48.000+02:00' }

        expose :web_url,
          documentation: {
            type: 'string',
            example: 'https://gitlab.example.com/gitlab-org/gitlab-foss/-/pipelines/61'
          } do |pipeline, _options|
          Gitlab::Routing.url_helpers.project_pipeline_url(pipeline.project, pipeline)
        end
      end
    end
  end
end
