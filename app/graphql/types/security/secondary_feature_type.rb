# frozen_string_literal: true

module Types
  module Security
    class SecondaryFeatureType < BaseObject # rubocop: disable Graphql/AuthorizeTypes -- Authorization at parent level
      graphql_name 'SecondarySecurityFeature'
      description 'Secondary security feature information.'

      field :configuration_text,
        GraphQL::Types::String,
        null: false,
        description: 'Display text for configuring the secondary feature.'

      field :description,
        GraphQL::Types::String,
        null: false,
        description: 'Description of what the secondary feature does.'

      field :name,
        GraphQL::Types::String,
        null: false,
        description: 'Name of the secondary feature.'

      field :type,
        GraphQL::Types::String,
        null: false,
        description: 'Type identifier for the secondary feature.'
    end
  end
end
