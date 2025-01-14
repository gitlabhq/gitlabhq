# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      # rubocop: disable Graphql/AuthorizeTypes
      class ResourceType < BaseObject
        graphql_name 'CiCatalogResource'

        connection_type_class Types::CountableConnectionType

        field :id, GraphQL::Types::ID, null: false,
          description: 'ID of the catalog resource.'

        field :name, GraphQL::Types::String, null: true,
          description: 'Name of the catalog resource.'

        field :description, GraphQL::Types::String, null: true,
          description: 'Description of the catalog resource.'

        field :topics, [GraphQL::Types::String], null: true,
          description: 'Topics for the catalog resource.'

        field :icon, GraphQL::Types::String, null: true,
          description: 'Icon for the catalog resource.',
          method: :avatar_path

        field :full_path, GraphQL::Types::ID, null: true,
          description: 'Full project path of the catalog resource.',
          experiment: { milestone: '16.11' }

        field :web_path, GraphQL::Types::String, null: true,
          description: 'Web path of the catalog resource.',
          experiment: { milestone: '16.1' }

        field :versions, Types::Ci::Catalog::Resources::VersionType.connection_type, null: true,
          description: 'Versions of the catalog resource. This field can only be ' \
            'resolved for one catalog resource in any single request.',
          resolver: Resolvers::Ci::Catalog::Resources::VersionsResolver

        field :visibility_level, Types::VisibilityLevelsEnum, null: true,
          description: 'Visibility level of the catalog resource.'

        field :verification_level, Types::Ci::Catalog::Resources::VerificationLevelEnum, null: true,
          description: 'Verification level of the catalog resource.'

        field :latest_released_at, Types::TimeType, null: true,
          description: "Release date of the catalog resource's latest version.",
          experiment: { milestone: '16.5' }

        field :star_count, GraphQL::Types::Int, null: false,
          description: 'Number of times the catalog resource has been starred.'

        field :starrers_path, GraphQL::Types::String, null: true,
          description: 'Relative path to the starrers page for the catalog resource project.'

        field :last_30_day_usage_count, GraphQL::Types::Int, null: false,
          description: 'Number of projects that used a component from this catalog resource in a pipeline, by using ' \
            '`include:component`, in the last 30 days.',
          experiment: { milestone: '17.0' }

        def web_path
          ::Gitlab::Routing.url_helpers.project_path(object.project)
        end

        def starrers_path
          Gitlab::Routing.url_helpers.project_starrers_path(object.project)
        end

        # rubocop: disable GraphQL/ResolverMethodLength -- this will be refactored:
        # https://gitlab.com/gitlab-org/gitlab/-/issues/510648
        def topics
          BatchLoader::GraphQL.for(object).batch do |resources, loader|
            # rubocop: disable CodeReuse/ActiveRecord -- this is necessary to batch
            project_ids = resources.pluck(:project_id)
            project_topics = ::Projects::ProjectTopic.where(project_id: project_ids)
            topics = ::Projects::Topic.where(id: project_topics.pluck(:topic_id))
            grouped_project_topics = project_topics.group_by(&:project_id)

            resources.each do |resource|
              project_topics_ids_for_resource = grouped_project_topics.fetch(resource.project_id,
                []).pluck(:topic_id)
              topics_for_resource = topics.select { |topic| project_topics_ids_for_resource.include?(topic.id) }

              loader.call(resource, topics_for_resource.pluck(:name))
              # rubocop: enable CodeReuse/ActiveRecord
            end
          end
        end
        # rubocop: enable GraphQL/ResolverMethodLength
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
