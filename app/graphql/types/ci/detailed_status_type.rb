# frozen_string_literal: true
module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `PipelineType` that has its own authorization
    class DetailedStatusType < BaseObject
      graphql_name 'DetailedStatus'

      field :group, GraphQL::STRING_TYPE, null: true,
            description: 'Group of the status'
      field :icon, GraphQL::STRING_TYPE, null: true,
            description: 'Icon of the status'
      field :favicon, GraphQL::STRING_TYPE, null: true,
            description: 'Favicon of the status'
      field :details_path, GraphQL::STRING_TYPE, null: true,
            description: 'Path of the details for the status'
      field :has_details, GraphQL::BOOLEAN_TYPE, null: true,
            description: 'Indicates if the status has further details',
            method: :has_details?
      field :label, GraphQL::STRING_TYPE, null: true,
            description: 'Label of the status'
      field :text, GraphQL::STRING_TYPE, null: true,
            description: 'Text of the status'
      field :tooltip, GraphQL::STRING_TYPE, null: true,
            description: 'Tooltip associated with the status',
            method: :status_tooltip
      field :action, Types::Ci::StatusActionType, null: true,
            description: 'Action information for the status. This includes method, button title, icon, path, and title',
            resolve: -> (obj, _args, _ctx) {
              if obj.has_action?
                {
                  button_title: obj.action_button_title,
                  icon: obj.action_icon,
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
