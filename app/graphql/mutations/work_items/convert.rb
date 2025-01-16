# frozen_string_literal: true

module Mutations
  module WorkItems
    class Convert < BaseMutation
      graphql_name 'WorkItemConvert'
      description "Converts the work item to a new type"

      include Mutations::SpamProtection

      authorize :update_work_item

      argument :id, ::Types::GlobalIDType[::WorkItem],
        required: true,
        description: 'Global ID of the work item.'
      argument :work_item_type_id, ::Types::GlobalIDType[::WorkItems::Type],
        required: true,
        description: 'Global ID of the new work item type.'

      field :work_item, ::Types::WorkItemType,
        null: true,
        description: 'Updated work item.'

      def resolve(attributes)
        work_item = authorized_find!(id: attributes[:id])

        work_item_type = find_work_item_type!(attributes[:work_item_type_id])
        authorize_work_item_type!(work_item, work_item_type)

        update_result = ::WorkItems::UpdateService.new(
          container: work_item.project,
          current_user: current_user,
          params: { work_item_type: work_item_type, issue_type: work_item_type.base_type },
          perform_spam_check: true
        ).execute(work_item)

        check_spam_action_response!(work_item)

        {
          work_item: (update_result[:work_item] if update_result[:status] == :success),
          errors: Array.wrap(update_result[:message])
        }
      end

      private

      def find_work_item_type!(gid)
        work_item_type = ::WorkItems::Type.find_by_correct_id_with_fallback(gid.model_id)

        return work_item_type if work_item_type.present?

        message = format(_('Work Item type with id %{id} was not found'), id: gid.model_id)
        raise_resource_not_available_error! message
      end

      def authorize_work_item_type!(work_item, work_item_type)
        return if current_user.can?(:"create_#{work_item_type.base_type}", work_item)

        message = format(_('You are not allowed to change the Work Item type to %{name}.'), name: work_item_type.name)
        raise_resource_not_available_error! message
      end
    end
  end
end
