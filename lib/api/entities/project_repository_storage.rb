# frozen_string_literal: true

module API
  module Entities
    class ProjectRepositoryStorage < Grape::Entity
      include Gitlab::Routing

      expose :disk_path, documentation: {
        type: 'String',
        example: '@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b'
      } do |project|
        project.repository.disk_path
      end

      expose :id, as: :project_id, documentation: { type: 'Integer', example: 1 }
      expose :repository_storage, documentation: { type: 'String', example: 'default' }
      expose :created_at, documentation: { type: 'DateTime', example: '2012-10-12T17:04:47Z' }
    end
  end
end
