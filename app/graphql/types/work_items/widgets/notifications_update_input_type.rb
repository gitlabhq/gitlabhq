# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class NotificationsUpdateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetNotificationsUpdateInput'

        argument :subscribed,
          GraphQL::Types::Boolean,
          required: true,
          description: 'Desired state of the subscription.'
      end
    end
  end
end
