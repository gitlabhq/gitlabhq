# frozen_string_literal: true

module API
  module Entities
    module ContainerRegistry
      class Tag < Grape::Entity
        expose :name
        expose :path
        expose :location
      end

      class Repository < Grape::Entity
        expose :id
        expose :name
        expose :path
        expose :project_id
        expose :location
        expose :created_at
        expose :tags_count, if: -> (_, options) { options[:tags_count] }
        expose :tags, using: Tag, if: -> (_, options) { options[:tags] }
      end

      class TagDetails < Tag
        expose :revision
        expose :short_revision
        expose :digest
        expose :created_at
        expose :total_size
      end
    end
  end
end
