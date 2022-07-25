# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetInterface
      include Types::BaseInterface

      graphql_name 'WorkItemWidget'

      field :type, ::Types::WorkItems::WidgetTypeEnum, null: true,
            description: 'Widget type.'

      ORPHAN_TYPES = [
        ::Types::WorkItems::Widgets::DescriptionType,
        ::Types::WorkItems::Widgets::HierarchyType,
        ::Types::WorkItems::Widgets::AssigneesType
      ].freeze

      def self.ce_orphan_types
        ORPHAN_TYPES
      end

      def self.resolve_type(object, context)
        case object
        when ::WorkItems::Widgets::Description
          ::Types::WorkItems::Widgets::DescriptionType
        when ::WorkItems::Widgets::Hierarchy
          ::Types::WorkItems::Widgets::HierarchyType
        when ::WorkItems::Widgets::Assignees
          ::Types::WorkItems::Widgets::AssigneesType
        else
          raise "Unknown GraphQL type for widget #{object}"
        end
      end

      orphan_types(*ORPHAN_TYPES)
    end
  end
end

Types::WorkItems::WidgetInterface.prepend_mod
