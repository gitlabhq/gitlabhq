# frozen_string_literal: true

module API
  module Entities
    class ProjectImportStatus < ProjectIdentity
      expose :import_status
      expose :import_type
      expose :correlation_id do |project, _options|
        project.import_state&.correlation_id
      end

      expose :failed_relations, using: Entities::ProjectImportFailedRelation do |project, _options|
        project.import_state&.relation_hard_failures(limit: 100) || []
      end

      expose :import_error do |project, _options|
        project.import_state&.last_error
      end

      expose :stats do |project, _options|
        if project.github_import?
          ::Gitlab::GithubImport::ObjectCounter.summary(project)
        end
      end
    end
  end
end
