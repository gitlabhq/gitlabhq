# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetDefinitionInterface
      include Types::BaseInterface

      graphql_name 'WorkItemWidgetDefinition'

      field :type, ::Types::WorkItems::WidgetTypeEnum,
        null: false,
        description: 'Widget type.'

      ORPHAN_TYPES = [
        ::Types::WorkItems::WidgetDefinitions::AssigneesType,
        ::Types::WorkItems::WidgetDefinitions::GenericType
      ].freeze

      def self.ce_orphan_types
        ORPHAN_TYPES
      end

      def self.resolve_type(object, _context)
        if object == ::WorkItems::Widgets::Assignees
          ::Types::WorkItems::WidgetDefinitions::AssigneesType
        else
          ::Types::WorkItems::WidgetDefinitions::GenericType
        end
      end

      orphan_types(*ce_orphan_types)
    end
  end
end

Types::WorkItems::WidgetDefinitionInterface.prepend_mod
