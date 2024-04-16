# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class DevelopmentType < BaseObject
        graphql_name 'WorkItemWidgetDevelopment'
        description 'Represents a development widget'

        implements Types::WorkItems::WidgetInterface
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end

Types::WorkItems::Widgets::DevelopmentType.prepend_mod
