# frozen_string_literal: true

module API
  module Entities
    module Projects
      class Topic < Grape::Entity
        expose :id
        expose :name
        expose :title
        expose :description
        expose :total_projects_count
        expose :organization_id
        expose :avatar_url do |topic, options|
          topic.avatar_url(only_path: false)
        end
      end
    end
  end
end
