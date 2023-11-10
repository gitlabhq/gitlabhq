# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # rubocop:disable Graphql/AuthorizeTypes
      class LinkedItemsType < BaseObject
        graphql_name 'WorkItemWidgetLinkedItems'
        description 'Represents the linked items widget'

        implements Types::WorkItems::WidgetInterface

        field :linked_items, Types::WorkItems::LinkedItemType.connection_type,
          null: true, complexity: 5,
          alpha: { milestone: '16.3' },
          extras: [:lookahead],
          description: 'Linked items for the work item. Returns `null` ' \
                       'if `linked_work_items` feature flag is disabled.',
          resolver: Resolvers::WorkItems::LinkedItemsResolver
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end

Types::WorkItems::Widgets::LinkedItemsType.prepend_mod
