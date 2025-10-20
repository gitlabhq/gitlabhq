# frozen_string_literal: true

module Types
  module WebHooks
    # rubocop: disable Graphql/AuthorizeTypes -- `object` is a hash, authorization handled on hook type and resolver
    class CustomHeaderType < BaseObject
      graphql_name 'WebhookCustomHeader'

      field :key, GraphQL::Types::String,
        null: false,
        description: 'Custom header name.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
