# frozen_string_literal: true

module API
  module Entities
    class RelationImportTracker < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :project_path, documentation: { type: 'String', example: 'namespace1/project1' } do |tracker|
        tracker.project.full_path
      end
      expose :relation, documentation: { type: 'String', example: 'issues' }
      expose :status, documentation: { type: 'string', example: 'pending' }, &:status_name
      expose :created_at, documentation: { type: 'DateTime', example: "2022-01-31T15:10:45.080Z" }
      expose :updated_at, documentation: { type: 'DateTime', example: "2022-01-31T15:10:45.080Z" }
    end
  end
end
