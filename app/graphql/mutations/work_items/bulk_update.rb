# frozen_string_literal: true

module Mutations
  module WorkItems
    class BulkUpdate < BaseMutation
      graphql_name 'WorkItemBulkUpdate'

      include ::Gitlab::Utils::StrongMemoize

      MAX_WORK_ITEMS = 100

      description 'Allows updating several properties for a set of work items. '

      argument :assignees_widget,
        ::Types::WorkItems::Widgets::AssigneesInputType,
        required: false,
        description: 'Input for assignees widget.',
        experiment: { milestone: '18.2' }
      argument :confidential,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Sets the work item confidentiality.',
        experiment: { milestone: '18.2' }
      argument :ids, [::Types::GlobalIDType[::WorkItem]],
        required: true,
        description: 'Global ID array of the work items that will be updated. ' \
          "IDs that the user can\'t update will be ignored. A max of #{MAX_WORK_ITEMS} can be provided."
      argument :milestone_widget,
        ::Types::WorkItems::Widgets::MilestoneInputType,
        required: false,
        description: 'Input for milestone widget.',
        experiment: { milestone: '18.2' }
      argument :state_event, ::Types::WorkItems::StateEventEnum,
        required: false,
        description: 'Close or reopen multiple work items at once.',
        experiment: { milestone: '18.2' }
      argument :subscription_event, ::Types::WorkItems::SubscriptionEventEnum,
        required: false,
        description: 'Subscribe or unsubscribe from the work items.',
        experiment: { milestone: '18.2' }

      argument :parent_id, ::Types::GlobalIDType[::WorkItems::Parent],
        required: true,
        description: 'Global ID of the parent to which the bulk update will be scoped. ' \
          'The parent can be a project. The parent can also be a group (Premium and Ultimate only). ' \
          'Example `WorkItemsParentID` are `"gid://gitlab/Project/1"` and `"gid://gitlab/Group/1"`.'

      argument :labels_widget,
        ::Types::WorkItems::Widgets::LabelsUpdateInputType,
        required: false,
        description: 'Input for labels widget.'

      argument :hierarchy_widget, ::Types::WorkItems::Widgets::HierarchyCreateInputType,
        required: false,
        description: 'Input for hierarchy widget.',
        experiment: { milestone: '18.2' }

      field :updated_work_item_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of work items that were successfully updated.'

      def ready?(**args)
        if args[:ids].size > MAX_WORK_ITEMS
          raise Gitlab::Graphql::Errors::ArgumentError,
            format(
              _('No more than %{max_work_items} work items can be updated at the same time'),
              max_work_items: MAX_WORK_ITEMS
            )
        end

        super
      end

      def resolve(ids:, parent_id:, **attributes)
        parent = parent_for!(parent_id)

        result = ::WorkItems::BulkUpdateService.new(
          parent: parent,
          current_user: current_user,
          work_item_ids: ids.map(&:model_id),
          attributes: attributes
        ).execute

        if result.success?
          { updated_work_item_count: result[:updated_work_item_count], errors: result.errors }
        else
          { errors: result.errors }
        end
      end

      private

      def parent_for!(parent_id)
        strong_memoize_with(:parent_for, parent_id) do
          parent = GitlabSchema.find_by_gid(parent_id).sync
          raise_resource_not_available_error! unless current_user.can?("read_#{parent.to_ability_name}", parent)

          parent
        end
      end
    end
  end
end

Mutations::WorkItems::BulkUpdate.prepend_mod
