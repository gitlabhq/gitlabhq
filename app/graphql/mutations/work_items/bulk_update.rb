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
        required: false,
        description: 'Global ID of the parent to which the bulk update will be scoped. ' \
          'The parent can be a project. The parent can also be a group (Premium and Ultimate only). ' \
          'Example `WorkItemsParentID` are `"gid://gitlab/Project/1"` and `"gid://gitlab/Group/1"`.',
        deprecated: { milestone: '18.2', reason: 'Use full_path instead' }

      argument :full_path, GraphQL::Types::ID,
        required: false,
        description: 'Full path of the project or group (Premium and Ultimate only) containing the work items that ' \
          'will be updated. User paths are not supported.',
        experiment: { milestone: '18.2' }

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

      validates exactly_one_of: [:full_path, :parent_id]

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

      def resolve(ids:, parent_id: nil, full_path: nil, **attributes)
        parent = resource_parent!(parent_id, full_path)

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

      def resource_parent!(parent_id, full_path)
        strong_memoize_with(:resource_parent, parent_id, full_path) do
          parent = parent_id ? GitlabSchema.find_by_gid(parent_id).sync : find_parent_by_full_path(full_path)

          unless parent && current_user.can?("read_#{parent.to_ability_name}", parent)
            raise_resource_not_available_error!
          end

          parent
        end
      end

      def find_parent_by_full_path(full_path, model = ::Project)
        # Note: Group support is added in the EE module. For CE, we only support bulk edit for projects
        ::Gitlab::Graphql::Loaders::FullPathModelLoader.new(model, full_path).find.sync
      end
    end
  end
end

Mutations::WorkItems::BulkUpdate.prepend_mod
