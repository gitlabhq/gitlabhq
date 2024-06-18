# frozen_string_literal: true

module API
  module Entities
    module ContainerRegistry
      class Tag < Grape::Entity
        expose :name, documentation: { type: 'string', example: 'latest' }
        expose :path, documentation: { type: 'string', example: 'namespace1/project1/test_image_1:latest' }
        expose :location, documentation: { type: 'string', example: 'registry.dev/namespace1/project1/test_image_1:latest' }
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
        expose :tags_count, if: ->(_, options) { options[:tags_count] }, documentation: { type: 'integer', example: 3 }
        expose :tags, using: Tag, if: ->(_, options) { options[:tags] }
        expose :delete_api_path, if: ->(object, options) { Ability.allowed?(options[:user], :admin_container_image, object) },
          documentation: { type: 'string', example: 'delete/api/path' }
        expose :size, if: ->(_, options) { options[:size] }, documentation: { type: 'integer', example: 12345 }
        expose :status, documentation: { type: 'string', example: 'delete_scheduled' }

        private

        def delete_api_path
          expose_url api_v4_projects_registry_repositories_path(repository_id: object.id, id: object.project_id)
        end
      end

      class TagDetails < Tag
        expose :revision, documentation: { type: 'string', example: 'tagrevision' }
        expose :short_revision, documentation: { type: 'string', example: 'shortrevison' }
        expose :digest, documentation: { type: 'string', example: 'shadigest' }
        expose :created_at, documentation: { type: 'dateTime', example: '2022-01-10T13:39:08.229Z' }
        expose :total_size, documentation: { type: 'integer', example: 3 }
      end
    end
  end
end
