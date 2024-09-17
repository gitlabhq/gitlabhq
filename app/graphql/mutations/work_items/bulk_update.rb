# frozen_string_literal: true

module Mutations
  module WorkItems
    class BulkUpdate < BaseMutation
      graphql_name 'WorkItemBulkUpdate'

      include ::Gitlab::Utils::StrongMemoize

      MAX_WORK_ITEMS = 100

      description 'Allows updating several properties for a set of issues. ' \
        'Does nothing if the `bulk_update_issues_mutation` feature flag is disabled.'

      argument :ids, [::Types::GlobalIDType[::WorkItem]],
        required: true,
        description: 'Global ID array of the issues that will be updated. ' \
          "IDs that the user can\'t update will be ignored. A max of #{MAX_WORK_ITEMS} can be provided."
      argument :parent_id, ::Types::GlobalIDType[::WorkItems::Parent],
        required: true,
        description: 'Global ID of the parent to which the bulk update will be scoped. ' \
          'The parent can be a project. The parent can also be a group (Premium and Ultimate only). ' \
          'Example `WorkItemsParentID` are `"gid://gitlab/Project/1"` and `"gid://gitlab/Group/1"`.'

      argument :labels_widget,
        ::Types::WorkItems::Widgets::LabelsUpdateInputType,
        required: false,
        description: 'Input for labels widget.',
        prepare: ->(input, _) { input.to_h }

      field :updated_work_item_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of work items that were successfully updated.'

      def ready?(**args)
        if Feature.disabled?(:bulk_update_work_items_mutation, parent_for!(args[:parent_id]))
          raise_resource_not_available_error!('`bulk_update_work_items_mutation` feature flag is disabled.')
        end

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
          widget_params: attributes
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
