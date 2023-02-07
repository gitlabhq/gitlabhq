# frozen_string_literal: true

module Import
  class GithubRealtimeRepoEntity < Grape::Entity
    expose :id, documentation: { type: 'integer', example: 1 }
    expose :import_status, documentation: { type: 'string', example: 'importing' }
    expose :stats,
      documentation: {
        type: 'object', example: '{"fetched":{"label":10},"imported":{"label":10}}'
      } do |project|
        ::Gitlab::GithubImport::ObjectCounter.summary(project)
      end

    expose :import_error, if: ->(project) { project.import_state&.failed? } do |project|
      project.import_failures.last&.exception_message
    end
  end
end
