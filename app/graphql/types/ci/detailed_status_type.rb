# frozen_string_literal: true
module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `PipelineType` that has its own authorization
    class DetailedStatusType < BaseObject
      graphql_name 'DetailedStatus'

      field :group, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :icon, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :favicon, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :details_path, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :has_details, GraphQL::BOOLEAN_TYPE, null: false, method: :has_details? # rubocop:disable Graphql/Descriptions
      field :label, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :text, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
      field :tooltip, GraphQL::STRING_TYPE, null: false, method: :status_tooltip # rubocop:disable Graphql/Descriptions
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
