# frozen_string_literal: true

module API
  module Entities
    class ProjectImportStatus < ProjectIdentity
      expose :import_status
      expose :correlation_id do |project, _options|
        project.import_state&.correlation_id
      end

      expose :failed_relations, using: Entities::ProjectImportFailedRelation do |project, _options|
        project.import_state.relation_hard_failures(limit: 100)
      end

      # TODO: Use `expose_nil` once we upgrade the grape-entity gem
      expose :import_error, if: lambda { |project, _ops| project.import_state&.last_error } do |project|
        project.import_state.last_error
      end
    end
  end
end
