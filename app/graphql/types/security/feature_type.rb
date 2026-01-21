# frozen_string_literal: true

module Types
  module Security
    class FeatureType < BaseObject # rubocop: disable Graphql/AuthorizeTypes -- Authorization is done at parent level
      graphql_name 'SecurityFeature'
      description 'Security feature information for a scan type.'

      field :anchor,
        GraphQL::Types::String,
        null: true,
        description: 'Anchor link for the security feature.'

      field :configuration_help_path,
        GraphQL::Types::String,
        null: true,
        description: 'Path to configuration help documentation.'

      field :description,
        GraphQL::Types::String,
        null: false,
        description: 'Description of what the security feature does.'

      field :help_path,
        GraphQL::Types::String,
        null: false,
        description: 'Path to help documentation for the security feature.'

      field :name,
        GraphQL::Types::String,
        null: false,
        description: 'Full name of the security feature.'

      field :secondary,
        Types::Security::SecondaryFeatureType,
        null: true,
        description: 'Secondary feature information.'

      field :short_name,
        GraphQL::Types::String,
        null: true,
        description: 'Short name of the security feature.'

      field :type,
        GraphQL::Types::String,
        null: false,
        description: 'Type identifier for the security feature.'
    end
  end
end
