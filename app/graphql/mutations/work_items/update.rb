# frozen_string_literal: true

module Mutations
  module WorkItems
    class Update < BaseMutation
      graphql_name 'WorkItemUpdate'
      description "Updates a work item by Global ID."

      include Mutations::SpamProtection
      include Mutations::WorkItems::UpdateArguments
      include Mutations::WorkItems::Widgetable

      authorize :update_work_item

      field :work_item, Types::WorkItemType,
            null: true,
            description: 'Updated work item.'

      def resolve(id:, **attributes)
        work_item = authorized_find!(id: id)

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])
        widget_params = extract_widget_params!(work_item.work_item_type, attributes)

        update_result = ::WorkItems::UpdateService.new(
          project: work_item.project,
          current_user: current_user,
          params: attributes,
          widget_params: widget_params,
          spam_params: spam_params
        ).execute(work_item)

        check_spam_action_response!(work_item)

        {
          work_item: (update_result[:work_item] if update_result[:status] == :success),
          errors: Array.wrap(update_result[:message])
        }
      end

      private

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end

Mutations::WorkItems::Update.prepend_mod
