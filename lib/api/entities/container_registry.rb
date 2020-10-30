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

        expose :id
        expose :name
        expose :path
        expose :project_id
        expose :location
        expose :created_at
        expose :expiration_policy_started_at, as: :cleanup_policy_started_at
        expose :tags_count, if: -> (_, options) { options[:tags_count] }
        expose :tags, using: Tag, if: -> (_, options) { options[:tags] }
        expose :delete_api_path, if: ->(object, options) { Ability.allowed?(options[:user], :admin_container_image, object) }

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
