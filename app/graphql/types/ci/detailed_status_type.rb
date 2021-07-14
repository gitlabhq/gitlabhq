# frozen_string_literal: true
module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `PipelineType` that has its own authorization
    class DetailedStatusType < BaseObject
      graphql_name 'DetailedStatus'

      field :id, GraphQL::STRING_TYPE, null: false,
            description: 'ID for a detailed status.',
            extras: [:parent]
      field :group, GraphQL::STRING_TYPE, null: true,
            description: 'Group of the status.'
      field :icon, GraphQL::STRING_TYPE, null: true,
            description: 'Icon of the status.'
      field :favicon, GraphQL::STRING_TYPE, null: true,
            description: 'Favicon of the status.'
      field :details_path, GraphQL::STRING_TYPE, null: true,
            description: 'Path of the details for the status.'
      field :has_details, GraphQL::BOOLEAN_TYPE, null: true,
            description: 'Indicates if the status has further details.',
            method: :has_details?
      field :label, GraphQL::STRING_TYPE, null: true,
            calls_gitaly: true,
            description: 'Label of the status.'
      field :text, GraphQL::STRING_TYPE, null: true,
            description: 'Text of the status.'
      field :tooltip, GraphQL::STRING_TYPE, null: true,
            description: 'Tooltip associated with the status.',
            method: :status_tooltip
      field :action, Types::Ci::StatusActionType, null: true,
            calls_gitaly: true,
            description: 'Action information for the status. This includes method, button title, icon, path, and title.'

      def id(parent:)
        "#{object.id}-#{parent.object.object.id}"
      end

      def action
        if object.has_action?
          {
            button_title: object.action_button_title,
            icon: object.action_icon,
            method: object.action_method,
            path: object.action_path,
            title: object.action_title
          }
        else
          nil
        end
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
