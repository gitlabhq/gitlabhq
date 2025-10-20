# frozen_string_literal: true

module Types
  module WebHooks
    # rubocop: disable Graphql/AuthorizeTypes -- `object` is a hash, authorization handled on hook type and resolver
    class UrlVariableType < BaseObject
      graphql_name 'WebhookUrlVariable'

      field :key, GraphQL::Types::String,
        null: false,
        description: 'URL variable mask that will appear in a masked webhook url in place of its sensitive portion.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
