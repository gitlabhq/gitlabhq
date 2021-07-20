# frozen_string_literal: true

module Types
  module Snippets
    # rubocop: disable Graphql/AuthorizeTypes
    class BlobType < BaseObject
      graphql_name 'SnippetBlob'
      description 'Represents the snippet blob'
      present_using SnippetBlobPresenter

      field :rich_data, GraphQL::STRING_TYPE,
            description: 'Blob highlighted data.',
            null: true

      field :plain_data, GraphQL::STRING_TYPE,
            description: 'Blob plain highlighted data.',
            null: true

      field :raw_plain_data, GraphQL::STRING_TYPE,
            description: 'The raw content of the blob, if the blob is text data.',
            null: true

      field :raw_path, GraphQL::STRING_TYPE,
            description: 'Blob raw content endpoint path.',
            null: false

      field :size, GraphQL::INT_TYPE,
            description: 'Blob size.',
            null: false

      field :binary, GraphQL::BOOLEAN_TYPE,
            description: 'Shows whether the blob is binary.',
            method: :binary?,
            null: false

      field :name, GraphQL::STRING_TYPE,
            description: 'Blob name.',
            null: true

      field :path, GraphQL::STRING_TYPE,
            description: 'Blob path.',
            null: true

      field :simple_viewer, type: Types::Snippets::BlobViewerType,
            description: 'Blob content simple viewer.',
            null: false

      field :rich_viewer, type: Types::Snippets::BlobViewerType,
            description: 'Blob content rich viewer.',
            null: true

      field :mode, type: GraphQL::STRING_TYPE,
            description: 'Blob mode.',
            null: true

      field :external_storage, type: GraphQL::STRING_TYPE,
            description: 'Blob external storage.',
            null: true

      field :rendered_as_text, type: GraphQL::BOOLEAN_TYPE,
            description: 'Shows whether the blob is rendered as text.',
            method: :rendered_as_text?,
            null: false
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
