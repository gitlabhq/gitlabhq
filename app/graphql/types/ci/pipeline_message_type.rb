# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class PipelineMessageType < BaseObject
      graphql_name 'PipelineMessage'

      field :id, GraphQL::Types::ID, null: false,
        description: 'ID of the pipeline message.'

      field :content, GraphQL::Types::String, null: false,
        description: 'Content of the pipeline message.'
    end
  end
end
