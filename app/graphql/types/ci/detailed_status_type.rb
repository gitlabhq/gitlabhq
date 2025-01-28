# frozen_string_literal: true
module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `PipelineType` that has its own authorization
    class DetailedStatusType < BaseObject
      graphql_name 'DetailedStatus'

      field :action,
        Types::Ci::StatusActionType,
        null: true,
        calls_gitaly: true,
        description: 'Action information for the status. This includes method, button title, icon, path, and title.'
      field :details_path, GraphQL::Types::String, null: true,
        description: 'Path of the details for the status.'
      field :favicon, GraphQL::Types::String, null: true,
        description: 'Favicon of the status.'
      field :group, GraphQL::Types::String, null: true,
        description: 'Group of the status.',
        deprecated: {
          reason: 'The `group` attribute is deprecated. Use `name` instead',
          milestone: '16.4'
        }
      field :has_details, GraphQL::Types::Boolean, null: true,
        description: 'Indicates if the status has further details.',
        method: :has_details?
      field :icon, GraphQL::Types::String, null: true,
        description: 'Icon of the status.',
        deprecated: {
          reason: 'The `icon` attribute is deprecated. Use `name` to ' \
            'identify the status to display instead',
          milestone: '16.4'
        }
      field :id, GraphQL::Types::String, null: false,
        description: 'ID for a detailed status.',
        extras: [:parent]
      field :label, GraphQL::Types::String, null: true,
        description: 'Human-readable label of the status (e.g. success).',
        calls_gitaly: true
      field :name, GraphQL::Types::String, null: true,
        description: 'Machine-readable status name (e.g. SUCCESS).'
      field :text, GraphQL::Types::String, null: true,
        description: 'Text of the status.',
        deprecated: {
          reason: 'The `text` attribute is being deprecated. Use `label` instead',
          milestone: '16.4'
        }
      field :tooltip, GraphQL::Types::String, null: true,
        description: 'Tooltip associated with the status.',
        method: :status_tooltip

      def id(parent:)
        "#{object.id}-#{parent.id}"
      end

      def action
        return unless object.has_action?

        {
          button_title: object.action_button_title,
          icon: object.action_icon,
          method: object.action_method,
          path: object.action_path,
          title: object.action_title,
          confirmation_message: object.confirmation_message
        }
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
