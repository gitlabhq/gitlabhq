# frozen_string_literal: true

module API
  module Entities
    class ProjectIdentity < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :description, documentation: { type: 'string', example: 'desc' }
      expose :name, documentation: { type: 'string', example: 'project1' }
      expose :name_with_namespace, documentation: { type: 'string', example: 'John Doe / project1' }
      expose :path, documentation: { type: 'string', example: 'project1' }
      expose :path_with_namespace, documentation: { type: 'string', example: 'namespace1/project1' }
      expose :created_at, documentation: { type: 'dateTime', example: '2020-05-07T04:27:17.016Z' }
    end
  end
end
