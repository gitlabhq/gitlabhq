# frozen_string_literal: true

module Types
  module Kas
    # rubocop: disable Graphql/AuthorizeTypes -- authorization is performed outside
    class AgentVersionWarningType < BaseObject
      graphql_name 'AgentVersionWarning'
      description 'Version-related warning for a connected Agent'

      field :message,
        GraphQL::Types::String,
        null: true,
        description: 'Warning message related to the version.'

      field :type,
        GraphQL::Types::String,
        null: true,
        description: 'Warning type related to the version.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
