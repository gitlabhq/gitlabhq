# frozen_string_literal: true

module API
  module Entities
    module Projects
      class Topic < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :name, documentation: { type: 'String', example: 'topic1' }
        expose :title, documentation: { type: 'String', example: 'Topic 1' }
        expose :description, documentation: { type: 'String', example: 'A description' }
        expose :total_projects_count, documentation: { type: 'Integer', example: 1 }
        expose :organization_id, documentation: { type: 'Integer', example: 1 }
        expose :avatar_url,
          documentation: { type: 'String',
                           example: 'http://gitlab.example.com/uploads/topic/avatar/1/avatar.png' } do |topic, options|
          topic.avatar_url(only_path: false)
        end
      end
    end
  end
end
