# frozen_string_literal: true

module Mutations
  module WorkItems
    class Update < BaseMutation
      graphql_name 'WorkItemUpdate'
      description "Updates a work item by Global ID." \
                  " Available only when feature flag `work_items` is enabled. The feature is experimental and is subject to change without notice."

      include Mutations::SpamProtection

      authorize :update_work_item

      argument :id, ::Types::GlobalIDType[::WorkItem],
               required: true,
               description: 'Global ID of the work item.'
      argument :state_event, Types::WorkItems::StateEventEnum,
               description: 'Close or reopen a work item.',
               required: false
      argument :title, GraphQL::Types::String,
               required: false,
               description: copy_field_description(Types::WorkItemType, :title)

      field :work_item, Types::WorkItemType,
            null: true,
            description: 'Updated work item.'

      def resolve(id:, **attributes)
        work_item = authorized_find!(id: id)

        unless Feature.enabled?(:work_items, work_item.project)
          return { errors: ['`work_items` feature flag disabled for this project'] }
        end

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])

        ::WorkItems::UpdateService.new(
          project: work_item.project,
          current_user: current_user,
          params: attributes,
          spam_params: spam_params
        ).execute(work_item)

        check_spam_action_response!(work_item)

        {
          work_item: work_item.valid? ? work_item : nil,
          errors: errors_on_object(work_item)
        }
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
