# frozen_string_literal: true

module Mutations
  module WorkItems
    class Update < BaseMutation
      graphql_name 'WorkItemUpdate'
      description "Updates a work item by Global ID."

      include Mutations::SpamProtection
      include Mutations::WorkItems::SharedArguments
      include Mutations::WorkItems::Widgetable

      authorize :read_work_item

      argument :award_emoji_widget,
        ::Types::WorkItems::Widgets::AwardEmojiUpdateInputType,
        required: false,
        description: 'Input for emoji reactions widget.'
      argument :crm_contacts_widget,
        ::Types::WorkItems::Widgets::CrmContactsUpdateInputType,
        required: false,
        description: 'Input for CRM contacts widget.'
      argument :current_user_todos_widget,
        ::Types::WorkItems::Widgets::CurrentUserTodosInputType,
        required: false,
        description: 'Input for to-dos widget.'
      argument :hierarchy_widget,
        ::Types::WorkItems::Widgets::HierarchyUpdateInputType,
        required: false,
        description: 'Input for hierarchy widget.'
      argument :id,
        ::Types::GlobalIDType[::WorkItem],
        required: true,
        description: 'Global ID of the work item.'
      argument :labels_widget,
        ::Types::WorkItems::Widgets::LabelsUpdateInputType,
        required: false,
        description: 'Input for labels widget.'
      argument :notes_widget,
        ::Types::WorkItems::Widgets::NotesInputType,
        required: false,
        description: 'Input for notes widget.'
      argument :notifications_widget,
        ::Types::WorkItems::Widgets::NotificationsUpdateInputType,
        required: false,
        description: 'Input for notifications widget.'
      argument :start_and_due_date_widget,
        ::Types::WorkItems::Widgets::StartAndDueDateUpdateInputType,
        required: false,
        description: 'Input for start and due date widget.'
      argument :state_event,
        ::Types::WorkItems::StateEventEnum,
        description: 'Close or reopen a work item.',
        required: false
      argument :time_tracking_widget,
        ::Types::WorkItems::Widgets::TimeTracking::TimeTrackingInputType,
        required: false,
        description: 'Input for time tracking widget.'
      argument :title,
        GraphQL::Types::String,
        required: false,
        description: copy_field_description(Types::WorkItemType, :title)

      field :work_item, ::Types::WorkItemType,
        null: true,
        description: 'Updated work item.'

      def resolve(id:, **attributes)
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/408575')

        work_item = authorized_find!(id: id)

        widget_params = extract_widget_params!(work_item.work_item_type, attributes, work_item.resource_parent)

        # Only checks permissions for base attributes because widgets define their own permissions independently
        raise_resource_not_available_error! unless attributes.empty? || can_update?(work_item)

        update_result = ::WorkItems::UpdateService.new(
          container: work_item.resource_parent,
          current_user: current_user,
          params: attributes,
          widget_params: widget_params,
          perform_spam_check: true
        ).execute(work_item)

        check_spam_action_response!(work_item)

        {
          work_item: (update_result[:work_item] if update_result[:status] == :success),
          errors: Array.wrap(update_result[:message])
        }
      end

      private

      def can_update?(work_item)
        current_user.can?(:update_work_item, work_item)
      end
    end
  end
end

Mutations::WorkItems::Update.prepend_mod
