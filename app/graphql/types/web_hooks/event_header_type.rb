# frozen_string_literal: true

module Types
  module WebHooks
    # rubocop: disable Graphql/AuthorizeTypes -- `object` is a hash, authorization handled on hook type and resolver
    class EventHeaderType < BaseObject
      graphql_name 'WebhookEventHeaderType'

      field :name, GraphQL::Types::String,
        null: false,
        description: 'HTTP response header name.'

      field :value, GraphQL::Types::String,
        null: false,
        description: 'HTTP response header value.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
