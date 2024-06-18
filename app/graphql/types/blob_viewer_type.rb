# frozen_string_literal: true

module Types
  class BlobViewerType < BaseObject # rubocop:disable Graphql/AuthorizeTypes
    graphql_name 'BlobViewer'
    description 'Represents how the blob content should be displayed'

    field :type, Types::BlobViewers::TypeEnum,
      description: 'Type of blob viewer.',
      null: false

    field :load_async, GraphQL::Types::Boolean,
      description: 'Shows whether the blob content is loaded asynchronously.',
      null: false

    field :collapsed, GraphQL::Types::Boolean,
      description: 'Shows whether the blob should be displayed collapsed.',
      method: :collapsed?,
      null: false

    field :too_large, GraphQL::Types::Boolean,
      description: 'Shows whether the blob is too large to be displayed.',
      method: :too_large?,
      null: false

    field :render_error, GraphQL::Types::String,
      description: 'Error rendering the blob content.',
      null: true

    field :file_type, GraphQL::Types::String,
      description: 'Content file type.',
      method: :partial_name,
      null: false

    field :loading_partial_name, GraphQL::Types::String,
      description: 'Loading partial name.',
      null: false

    def collapsed
      !!object&.collapsed?
    end

    def too_large
      !!object&.too_large?
    end
  end
end
