# frozen_string_literal: true

module API
  module Entities
    module ContainerRegistry
      class Repository < Grape::Entity
        expose :id
        expose :name
        expose :path
        expose :location
        expose :created_at
      end

      class Tag < Grape::Entity
        expose :name
        expose :path
        expose :location
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
