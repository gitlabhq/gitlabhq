# frozen_string_literal: true

module Mutations
  module WorkItems
    class Update < BaseMutation
      graphql_name 'WorkItemUpdate'
      description "Updates a work item by Global ID."

      include Mutations::SpamProtection
      include Mutations::WorkItems::UpdateArguments
      include Mutations::WorkItems::Widgetable

      authorize :read_work_item

      field :work_item, Types::WorkItemType,
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
