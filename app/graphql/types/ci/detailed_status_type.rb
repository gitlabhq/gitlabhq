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
      field :action, Types::Ci::StatusActionType, null: true,
            description: 'Action information for the status. This includes method, button title, icon, path, and title',
            resolve: -> (obj, _args, _ctx) {
              if obj.has_action?
                {
                  button_title: obj.action_button_title,
                  icon: obj.icon,
                  method: obj.action_method,
                  path: obj.action_path,
                  title: obj.action_title
                }
              else
                nil
              end
            }
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
