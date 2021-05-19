# frozen_string_literal: true

module Types
  module Snippets
    # Kept to avoid changing the type of existing fields. New fields should use
    # ::Types::BlobViewerType directly
    class BlobViewerType < ::Types::BlobViewerType # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'SnippetBlobViewer'
    end
  end
end
