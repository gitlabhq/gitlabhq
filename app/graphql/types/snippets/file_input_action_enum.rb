# frozen_string_literal: true

module Types
  module Snippets
    class FileInputActionEnum < BaseEnum
      graphql_name 'SnippetFileInputActionEnum'
      description 'Type of a snippet file input action'

      value 'create', value: :create
      value 'update', value: :update
      value 'delete', value: :delete
      value 'move', value: :move
    end
  end
end
