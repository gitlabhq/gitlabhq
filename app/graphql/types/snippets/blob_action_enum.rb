# frozen_string_literal: true

module Types
  module Snippets
    class BlobActionEnum < BaseEnum
      graphql_name 'SnippetBlobActionEnum'
      description 'Type of a snippet blob input action'

      value 'create', description: 'Create a snippet blob.', value: :create
      value 'update', description: 'Update a snippet blob.', value: :update
      value 'delete', description: 'Delete a snippet blob.', value: :delete
      value 'move', description: 'Move a snippet blob.', value: :move
    end
  end
end
