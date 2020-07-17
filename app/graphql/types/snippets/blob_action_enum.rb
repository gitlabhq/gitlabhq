# frozen_string_literal: true

module Types
  module Snippets
    class BlobActionEnum < BaseEnum
      graphql_name 'SnippetBlobActionEnum'
      description 'Type of a snippet blob input action'

      value 'create', value: :create
      value 'update', value: :update
      value 'delete', value: :delete
      value 'move', value: :move
    end
  end
end
