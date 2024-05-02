# frozen_string_literal: true

module Types
  module Snippets
    # rubocop: disable Graphql/AuthorizeTypes
    class BlobConnectionType < GraphQL::Types::Relay::BaseConnection
      field :has_unretrievable_blobs,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates if the snippet has unretrievable blobs.',
        resolver_method: :unretrievable_blobs?

      def unretrievable_blobs?
        !!context[:unretrievable_blobs?]
      end
    end
  end
end
