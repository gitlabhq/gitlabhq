# frozen_string_literal: true

module Types
  class IdeType < BaseObject
    graphql_name 'Ide'
    description 'IDE settings and feature flags.'

    authorize :read_user

    field :code_suggestions_enabled, GraphQL::Types::Boolean, null: false,
      description: 'Indicates whether AI assisted code suggestions are enabled.'

    def code_suggestions_enabled
      object.can?(:access_code_suggestions)
    end
  end
end
