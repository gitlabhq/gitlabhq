# frozen_string_literal: true

module API
  module Entities
    class ProjectImportStatus < ProjectIdentity
      expose :import_status, documentation: { type: 'string', example: 'scheduled' }
      expose :import_type, documentation: { type: 'string', example: 'gitlab_project' }
      expose :correlation_id, documentation: {
        type: 'string', example: 'dfcf583058ed4508e4c7c617bd7f0edd'
      } do |project, _options|
        project.import_state&.correlation_id
      end

      expose :failed_relations, using: Entities::ProjectImportFailedRelation, documentation: {
        is_array: true
      } do |project, _options|
        project.import_state&.relation_hard_failures(limit: 100) || []
      end

      expose :import_error, documentation: { type: 'string', example: 'Error message' } do |project, _options|
        project.import_state&.last_error
      end

      expose :stats, documentation: { type: 'object' } do |project, _options|
        if project.github_import?
          ::Gitlab::GithubImport::ObjectCounter.summary(project)
        end
      end
    end
  end
end
