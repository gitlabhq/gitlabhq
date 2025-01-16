# frozen_string_literal: true

module Mutations
  module WorkItems
    class CreateFromTask < BaseMutation
      graphql_name 'WorkItemCreateFromTask'

      include Mutations::SpamProtection

      description "Creates a work item from a task in another work item's description."

      authorize :update_work_item

      argument :id, ::Types::GlobalIDType[::WorkItem],
        required: true,
        description: 'Global ID of the work item.'
      argument :work_item_data, ::Types::WorkItems::ConvertTaskInputType,
        required: true,
        description: 'Arguments necessary to convert a task into a work item.',
        prepare: ->(attributes, _ctx) { attributes.to_h }

      field :work_item, ::Types::WorkItemType,
        null: true,
        description: 'Updated work item.'

      field :new_work_item, ::Types::WorkItemType,
        null: true,
        description: 'New work item created from task.'

      def resolve(id:, work_item_data:)
        work_item = authorized_find!(id: id)

        result = ::WorkItems::CreateFromTaskService.new(
          work_item: work_item,
          current_user: current_user,
          work_item_params: work_item_data_with_fallback_type(work_item_data)
        ).execute

        check_spam_action_response!(result[:work_item]) if result[:work_item]

        response = { errors: result.errors }
        response.merge!(work_item: work_item, new_work_item: result[:work_item]) if result.success?

        response
      end

      private

      def work_item_data_with_fallback_type(work_item_data)
        work_item_type_id = work_item_data.delete(:work_item_type_id)
        work_item_type = ::WorkItems::Type.find_by_correct_id_with_fallback(work_item_type_id)

        work_item_data[:work_item_type] = work_item_type

        work_item_data
      end
    end
  end
end
