# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetInterface
      include ::Types::BaseInterface

      graphql_name 'WorkItemWidget'

      field :type,
        ::Types::WorkItems::WidgetTypeEnum,
        null: true,
        description: 'Widget type.'

      # Whenever a new widget is added make sure to update the spec to avoid N + 1 queries in
      # spec/requests/api/graphql/project/work_items_spec.rb and add the necessary preloads
      # in app/graphql/resolvers/work_items_resolver.rb
      TYPE_MAPPINGS = {
        ::WorkItems::Widgets::Description => ::Types::WorkItems::Widgets::DescriptionType,
        ::WorkItems::Widgets::Hierarchy => ::Types::WorkItems::Widgets::HierarchyType,
        ::WorkItems::Widgets::Labels => ::Types::WorkItems::Widgets::LabelsType,
        ::WorkItems::Widgets::Assignees => ::Types::WorkItems::Widgets::AssigneesType,
        ::WorkItems::Widgets::StartAndDueDate => ::Types::WorkItems::Widgets::StartAndDueDateType,
        ::WorkItems::Widgets::Milestone => ::Types::WorkItems::Widgets::MilestoneType,
        ::WorkItems::Widgets::Notes => ::Types::WorkItems::Widgets::NotesType,
        ::WorkItems::Widgets::Notifications => ::Types::WorkItems::Widgets::NotificationsType,
        ::WorkItems::Widgets::CurrentUserTodos => ::Types::WorkItems::Widgets::CurrentUserTodosType,
        ::WorkItems::Widgets::AwardEmoji => ::Types::WorkItems::Widgets::AwardEmojiType,
        ::WorkItems::Widgets::LinkedItems => ::Types::WorkItems::Widgets::LinkedItemsType,
        ::WorkItems::Widgets::Participants => ::Types::WorkItems::Widgets::ParticipantsType,
        ::WorkItems::Widgets::TimeTracking => ::Types::WorkItems::Widgets::TimeTracking::TimeTrackingType,
        ::WorkItems::Widgets::Designs => ::Types::WorkItems::Widgets::DesignsType,
        ::WorkItems::Widgets::Development => ::Types::WorkItems::Widgets::DevelopmentType,
        ::WorkItems::Widgets::CrmContacts => ::Types::WorkItems::Widgets::CrmContactsType,
        ::WorkItems::Widgets::EmailParticipants => ::Types::WorkItems::Widgets::EmailParticipantsType,
        ::WorkItems::Widgets::CustomStatus => ::Types::WorkItems::Widgets::CustomStatusType,
        ::WorkItems::Widgets::LinkedResources => ::Types::WorkItems::Widgets::LinkedResourcesType
      }.freeze

      def self.type_mappings
        TYPE_MAPPINGS
      end

      def self.resolve_type(object, context)
        type_mappings[object.class] || raise("Unknown GraphQL type for widget #{object}")
      end

      orphan_types(*type_mappings.values)
    end
  end
end

Types::WorkItems::WidgetInterface.prepend_mod
