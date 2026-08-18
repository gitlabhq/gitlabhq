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
      authorize_granular_token permissions: :update_work_item,
        boundaries: [
          { boundary_argument: :id, boundary: :resource_parent, boundary_type: :project },
          { boundary_argument: :id, boundary: :resource_parent, boundary_type: :group }
        ]

      def self.authorization_scopes
        super + [:ai_workflows]
      end

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
      argument :move_after_id,
        ::Types::GlobalIDType[::WorkItem],
        required: false,
        experiment: { milestone: '19.2' },
        description: 'Global ID of a work item that should be placed after the work item.',
        prepare: ->(id, _ctx) { GitlabSchema.parse_gid(id)&.model_id }
      argument :move_before_id,
        ::Types::GlobalIDType[::WorkItem],
        required: false,
        experiment: { milestone: '19.2' },
        description: 'Global ID of a work item that should be placed before the work item.',
        prepare: ->(id, _ctx) { GitlabSchema.parse_gid(id)&.model_id }
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
        description: copy_field_description(::Types::WorkItemType, :title)

      field :work_item, ::Types::WorkItemType,
        null: true, scopes: [:api, :ai_workflows],
        description: 'Updated work item.'

      field :errors, [GraphQL::Types::String],
        null: false,
        scopes: [:api, :ai_workflows],
        description: 'Errors encountered during the mutation.'

      def resolve(id:, **attributes)
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/408575')

        work_item = authorized_find!(id: id)

        move_between_ids = build_move_between_ids(attributes)

        widget_params = extract_widget_params!(work_item.work_item_type, attributes, work_item.resource_parent)

        # Treat reordering as a base attribute so it is covered by the permission check below.
        attributes[:move_between_ids] = move_between_ids if move_between_ids

        extract_task_list_toggle!(work_item, attributes, widget_params)

        # Only checks permissions for base attributes because widgets define their own permissions independently.
        raise_resource_not_available_error! if attributes.present? && !can_update?(work_item)

        params = attributes.merge(scope_validator: context[:scope_validator])

        begin
          update_result = ::WorkItems::UpdateService.new(
            container: work_item.resource_parent,
            current_user: current_user,
            params: params,
            widget_params: widget_params,
            perform_spam_check: true
          ).execute(work_item)
        rescue ActiveRecord::StaleObjectError => e
          raise if e.attempted_action != IssuableBaseService::TOGGLE_TASK_ITEM_ACTION

          # Raised by the task list toggle path when the targeted line no longer
          # matches what the client saw. Return the current server state so
          # clients can recover without a refetch.
          return {
            work_item: work_item.reset,
            errors: [format(
              _("Someone edited this %{issueType} at the same time you did. " \
                "The description has been updated and you will need to make your changes again."),
              issueType: work_item.work_item_type.name.downcase
            )]
          }
        end

        check_spam_action_response!(work_item)

        {
          work_item: (update_result[:work_item] if update_result[:status] == :success),
          errors: Array.wrap(update_result[:message])
        }
      end

      private

      def build_move_between_ids(attributes)
        Gitlab::RelativePositioning.parse_move_between_ids(
          attributes.delete(:move_before_id),
          attributes.delete(:move_after_id)
        )
      end

      def can_update?(work_item)
        current_user.can?(:update_work_item, work_item)
      end

      # The task list toggle arrives in the description widget, but it's executed
      # by `update_task` (IssuableBaseService#update_task_event), which doesn't
      # run widget callbacks => no widget-level permission checking.
      #
      # We move it into the base attributes to ensure it triggers the `can_update?` check.
      def extract_task_list_toggle!(work_item, attributes, widget_params)
        toggle = widget_params[:description_widget]&.delete(:task_list_toggle)
        return unless toggle

        if Feature.disabled?(:work_items_task_list_toggle, work_item.resource_parent)
          raise Gitlab::Graphql::Errors::ArgumentError,
            '`taskListToggle` is not available. The `work_items_task_list_toggle` feature flag is disabled.'
        end

        # `update_task` path doesn't run any other normal update processing,
        # so deny combining toggle with anything else.
        if attributes.present? || widget_params.except(:description_widget).present?
          raise Gitlab::Graphql::Errors::ArgumentError,
            '`taskListToggle` cannot be combined with other arguments'
        end

        widget_params.delete(:description_widget)

        attributes[:update_task] = {
          checked: toggle[:checked],
          line_source: toggle[:line_source],
          line_sourcepos: toggle[:line_sourcepos]
        }
      end
    end
  end
end

Mutations::WorkItems::Update.prepend_mod
