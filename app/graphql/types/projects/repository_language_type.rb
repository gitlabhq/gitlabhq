# frozen_string_literal: true

module Types
  module Projects
    # rubocop: disable Graphql/AuthorizeTypes
    class RepositoryLanguageType < BaseObject
      graphql_name 'RepositoryLanguage'

      def self.authorization_scopes
        super + [:ai_workflows]
      end

      field :name, GraphQL::Types::String, null: false,
        description: 'Name of the repository language.',
        scopes: [:api, :read_api, :ai_workflows]

      field :share, GraphQL::Types::Float, null: true,
        description: "Percentage of the repository's languages.",
        scopes: [:api, :read_api, :ai_workflows]

      field :color, Types::ColorType, null: true,
        description: 'Color to visualize the repository language.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
