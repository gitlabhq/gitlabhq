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
          return false unless current_user

          work_item = object.work_item

          BatchLoader::GraphQL.for(work_item).batch do |work_items, loader|
            batch_load_subscriptions(work_items, loader)
          end
        end

        private

        def batch_load_subscriptions(work_items, loader)
          subscriptions = ::Subscription
            .for_subscribables(work_items.map(&:id), WorkItem.polymorphic_name)
            .for_user(current_user)
            .index_by(&:subscribable_id)

          work_items.each do |wi|
            subscription = subscriptions[wi.id]
            loader.call(wi, subscription ? subscription.subscribed : wi.participant?(current_user))
          end
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
