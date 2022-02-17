# frozen_string_literal: true

module Mutations
  module WorkItems
    class CreateFromTask < BaseMutation
      include Mutations::SpamProtection

      description "Creates a work item from a task in another work item's description." \
                  " Available only when feature flag `work_items` is enabled. This feature is experimental and is subject to change without notice."

      graphql_name 'WorkItemCreateFromTask'

      authorize :update_work_item

      argument :id, ::Types::GlobalIDType[::WorkItem],
               required: true,
               description: 'Global ID of the work item.'
      argument :work_item_data, ::Types::WorkItems::ConvertTaskInputType,
               required: true,
               description: 'Arguments necessary to convert a task into a work item.',
               prepare: ->(attributes, _ctx) { attributes.to_h }

      field :work_item, Types::WorkItemType,
            null: true,
            description: 'Updated work item.'

      field :new_work_item, Types::WorkItemType,
            null: true,
            description: 'New work item created from task.'

      def resolve(id:, work_item_data:)
        work_item = authorized_find!(id: id)

        unless Feature.enabled?(:work_items, work_item.project)
          return { errors: ['`work_items` feature flag disabled for this project'] }
        end

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])

        result = ::WorkItems::CreateFromTaskService.new(
          work_item: work_item,
          current_user: current_user,
          work_item_params: work_item_data,
          spam_params: spam_params
        ).execute

        check_spam_action_response!(result[:work_item]) if result[:work_item]

        response = { errors: result.errors }
        response.merge!(work_item: work_item, new_work_item: result[:work_item]) if result.success?

        response
      end

      private

      def find_object(id:)
        # TODO: Remove coercion when working on https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::WorkItem].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
