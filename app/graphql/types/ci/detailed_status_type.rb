# frozen_string_literal: true
module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `PipelineType` that has its own authorization
    class DetailedStatusType < BaseObject
      graphql_name 'DetailedStatus'

      field :group, GraphQL::STRING_TYPE, null: false,
            description: 'Group of the pipeline status'
      field :icon, GraphQL::STRING_TYPE, null: false,
            description: 'Icon of the pipeline status'
      field :favicon, GraphQL::STRING_TYPE, null: false,
            description: 'Favicon of the pipeline status'
      field :details_path, GraphQL::STRING_TYPE, null: false,
            description: 'Path of the details for the pipeline status'
      field :has_details, GraphQL::BOOLEAN_TYPE, null: false,
            description: 'Indicates if the pipeline status has further details',
            method: :has_details?
      field :label, GraphQL::STRING_TYPE, null: false,
            description: 'Label of the pipeline status'
      field :text, GraphQL::STRING_TYPE, null: false,
            description: 'Text of the pipeline status'
      field :tooltip, GraphQL::STRING_TYPE, null: false,
            description: 'Tooltip associated with the pipeline status',
            method: :status_tooltip
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
