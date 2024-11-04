# frozen_string_literal: true

module Types
  module Packages
    module Helm
      # rubocop: disable Graphql/AuthorizeTypes
      class DependencyType < BaseObject
        graphql_name 'PackageHelmDependencyType'
        description 'Represents a Helm dependency'

        # Need to be synced with app/validators/json_schemas/helm_metadata.json#dependencies
        field :alias,
          GraphQL::Types::String,
          null: true,
          description: 'Alias of the dependency.',
          resolver_method: :resolve_alias
        field :condition, GraphQL::Types::String, null: true, description: 'Condition of the dependency.'
        field :enabled, GraphQL::Types::Boolean, null: true, description: 'Indicates the dependency is enabled.'
        field :import_values, [GraphQL::Types::JSON], null: true, description: 'Import-values of the dependency.',
          hash_key: :'import-values'
        field :name, GraphQL::Types::String, null: true, description: 'Name of the dependency.'
        field :repository, GraphQL::Types::String, null: true, description: 'Repository of the dependency.'
        field :tags, [GraphQL::Types::String], null: true, description: 'Tags of the dependency.'
        field :version, GraphQL::Types::String, null: true, description: 'Version of the dependency.'

        # field :alias` conflicts with a built-in method
        def resolve_alias
          object['alias']
        end
      end
    end
  end
end
