# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class NotificationsType < BaseObject
        graphql_name 'WorkItemWidgetNotifications'
        description 'Represents the notifications widget'

        implements ::Types::WorkItems::WidgetInterface

        field :subscribed, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the current user is subscribed to notifications on the work item.'

        def subscribed
          object.work_item.subscribed?(current_user, object.work_item.project)
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
