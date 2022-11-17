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
        include ::API::Helpers::RelatedResourcesHelpers

        expose :id, documentation: { type: 'integer', example: 1 }
        expose :name, documentation: { type: 'string', example: 'releases' }
        expose :path, documentation: { type: 'string', example: 'group/project/releases' }
        expose :project_id, documentation: { type: 'integer', example: 9 }
        expose :location, documentation: { type: 'string', example: 'gitlab.example.com/group/project/releases' }
        expose :created_at, documentation: { type: 'dateTime', example: '2019-01-10T13:39:08.229Z' }
        expose :expiration_policy_started_at, as: :cleanup_policy_started_at, documentation: { type: 'dateTime', example: '2020-08-17T03:12:35.489Z' }
        expose :tags_count, if: -> (_, options) { options[:tags_count] }
        expose :tags, using: Tag, if: -> (_, options) { options[:tags] }
        expose :delete_api_path, if: ->(object, options) { Ability.allowed?(options[:user], :admin_container_image, object) }
        expose :size, if: -> (_, options) { options[:size] }

        private

        def delete_api_path
          expose_url api_v4_projects_registry_repositories_path(repository_id: object.id, id: object.project_id)
        end
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
