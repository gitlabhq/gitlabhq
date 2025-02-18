# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetDefinitionInterface
      include ::Types::BaseInterface

      graphql_name 'WorkItemWidgetDefinition'

      field :type, ::Types::WorkItems::WidgetTypeEnum,
        null: false,
        description: 'Widget type.'

      ORPHAN_TYPES = [
        ::Types::WorkItems::WidgetDefinitions::AssigneesType,
        ::Types::WorkItems::WidgetDefinitions::GenericType,
        ::Types::WorkItems::WidgetDefinitions::HierarchyType,
        ::Types::WorkItems::WidgetDefinitions::CustomStatusType
      ].freeze

      TYPE_MAPPING = {
        ::WorkItems::Widgets::Assignees => ::Types::WorkItems::WidgetDefinitions::AssigneesType,
        ::WorkItems::Widgets::Hierarchy => ::Types::WorkItems::WidgetDefinitions::HierarchyType,
        ::WorkItems::Widgets::CustomStatus => ::Types::WorkItems::WidgetDefinitions::CustomStatusType
      }.freeze

      def self.ce_orphan_types
        ORPHAN_TYPES
      end

      def self.resolve_type(object, _context)
        TYPE_MAPPING[object.widget_class] || ::Types::WorkItems::WidgetDefinitions::GenericType
      end

      def type
        object.widget_class.type
      end

      orphan_types(*ce_orphan_types)
    end
  end
end

Types::WorkItems::WidgetDefinitionInterface.prepend_mod
