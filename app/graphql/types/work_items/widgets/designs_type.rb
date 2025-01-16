# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class DesignsType < BaseObject
        graphql_name 'WorkItemWidgetDesigns'
        description 'Represents designs widget'

        implements ::Types::WorkItems::WidgetInterface

        field :design_collection, ::Types::DesignManagement::DesignCollectionType, null: true,
          description: 'Collection of design images associated with the issue.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
