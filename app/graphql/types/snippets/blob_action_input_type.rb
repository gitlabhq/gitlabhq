# frozen_string_literal: true

module Types
  module Snippets
    class BlobActionInputType < BaseInputObject
      graphql_name 'SnippetBlobActionInputType'
      description 'Represents an action to perform over a snippet file'

      argument :action, Types::Snippets::BlobActionEnum,
        description: 'Type of input action.',
        required: true

      argument :previous_path, GraphQL::Types::String,
        description: 'Previous path of the snippet file.',
        required: false

      argument :file_path, GraphQL::Types::String,
        description: 'Path of the snippet file.',
        required: true

      argument :content, GraphQL::Types::String,
        description: 'Snippet file content.',
        required: false
    end
  end
end
