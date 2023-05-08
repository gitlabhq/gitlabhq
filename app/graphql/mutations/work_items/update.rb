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
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/408575')

        work_item = authorized_find!(id: id)

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])
        widget_params = extract_widget_params!(work_item.work_item_type, attributes)

        interpret_quick_actions!(work_item, current_user, widget_params, attributes)

        update_result = ::WorkItems::UpdateService.new(
          container: work_item.project,
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

      def interpret_quick_actions!(work_item, current_user, widget_params, attributes = {})
        return unless work_item.work_item_type.widgets.include?(::WorkItems::Widgets::Description)

        description_param = widget_params[::WorkItems::Widgets::Description.api_symbol]
        return unless description_param

        original_description = description_param.fetch(:description, work_item.description)

        description, command_params = QuickActions::InterpretService
            .new(work_item.project, current_user, {})
            .execute(original_description, work_item)

        description_param[:description] = description if description && description != original_description

        parsed_params = work_item.transform_quick_action_params(command_params)

        widget_params.merge!(parsed_params[:widgets])
        attributes.merge!(parsed_params[:common])
      end
    end
  end
end

Mutations::WorkItems::Update.prepend_mod
