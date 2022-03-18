# frozen_string_literal: true

module Types
  module Packages
    module Helm
      # rubocop: disable Graphql/AuthorizeTypes
      class MaintainerType < BaseObject
        graphql_name 'PackageHelmMaintainerType'
        description 'Represents a Helm maintainer'

        # Need to be synced with app/validators/json_schemas/helm_metadata.json#maintainers
        field :email, GraphQL::Types::String, null: true, description: 'Email of the maintainer.'
        field :name, GraphQL::Types::String, null: true, description: 'Name of the maintainer.'
        field :url, GraphQL::Types::String, null: true, description: 'URL of the maintainer.'
      end
    end
  end
end
