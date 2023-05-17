# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetInterface
      include Types::BaseInterface

      graphql_name 'WorkItemWidget'

      field :type, ::Types::WorkItems::WidgetTypeEnum,
        null: true,
        description: 'Widget type.'

      ORPHAN_TYPES = [
        ::Types::WorkItems::Widgets::DescriptionType,
        ::Types::WorkItems::Widgets::HierarchyType,
        ::Types::WorkItems::Widgets::LabelsType,
        ::Types::WorkItems::Widgets::AssigneesType,
        ::Types::WorkItems::Widgets::StartAndDueDateType,
        ::Types::WorkItems::Widgets::MilestoneType,
        ::Types::WorkItems::Widgets::NotesType,
        ::Types::WorkItems::Widgets::NotificationsType,
        ::Types::WorkItems::Widgets::CurrentUserTodosType,
        ::Types::WorkItems::Widgets::AwardEmojiType
      ].freeze

      def self.ce_orphan_types
        ORPHAN_TYPES
      end

      # Whenever a new widget is added make sure to update the spec to avoid N + 1 queries in
      # spec/requests/api/graphql/project/work_items_spec.rb and add the necessary preloads
      # in app/graphql/resolvers/work_items_resolver.rb
      def self.resolve_type(object, context)
        case object
        when ::WorkItems::Widgets::Description
          ::Types::WorkItems::Widgets::DescriptionType
        when ::WorkItems::Widgets::Hierarchy
          ::Types::WorkItems::Widgets::HierarchyType
        when ::WorkItems::Widgets::Assignees
          ::Types::WorkItems::Widgets::AssigneesType
        when ::WorkItems::Widgets::Labels
          ::Types::WorkItems::Widgets::LabelsType
        when ::WorkItems::Widgets::StartAndDueDate
          ::Types::WorkItems::Widgets::StartAndDueDateType
        when ::WorkItems::Widgets::Milestone
          ::Types::WorkItems::Widgets::MilestoneType
        when ::WorkItems::Widgets::Notes
          ::Types::WorkItems::Widgets::NotesType
        when ::WorkItems::Widgets::Notifications
          ::Types::WorkItems::Widgets::NotificationsType
        when ::WorkItems::Widgets::CurrentUserTodos
          ::Types::WorkItems::Widgets::CurrentUserTodosType
        when ::WorkItems::Widgets::AwardEmoji
          ::Types::WorkItems::Widgets::AwardEmojiType
        else
          raise "Unknown GraphQL type for widget #{object}"
        end
      end

      orphan_types(*ORPHAN_TYPES)
    end
  end
end

Types::WorkItems::WidgetInterface.prepend_mod
