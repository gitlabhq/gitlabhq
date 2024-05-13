# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class NestedEnvironmentType < BaseObject
    graphql_name 'NestedEnvironment'
    description 'Describes where code is deployed for a project organized by folder.'

    field :name, GraphQL::Types::String,
      null: false, description: 'Human-readable name of the environment.'

    field :size, GraphQL::Types::Int,
      null: false, description: 'Number of environments nested in the folder.'

    field :environment,
      Types::EnvironmentType,
      null: true, description: 'Latest environment in the folder.'

    def environment
      BatchLoader::GraphQL.for(object.last_id).batch do |environment_ids, loader|
        Environment.id_in(environment_ids).each do |environment|
          loader.call(environment.id, environment)
        end
      end
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
