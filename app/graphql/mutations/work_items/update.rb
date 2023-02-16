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

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end

      def interpret_quick_actions!(work_item, current_user, widget_params, attributes = {})
        return unless work_item.work_item_type.widgets.include?(::WorkItems::Widgets::Description)

        description_param = widget_params[::WorkItems::Widgets::Description.api_symbol]
        return unless description_param

        original_description = description_param.fetch(:description, work_item.description)

        description, command_params = QuickActions::InterpretService
            .new(work_item.project, current_user, {})
            .execute(original_description, work_item)

        description_param[:description] = description if description && description != original_description

        # Widgets have a set of quick action params that they must process.
        # Map them to widget_params so they can be picked up by widget services.
        work_item.work_item_type.widgets
          .filter { |widget| widget.respond_to?(:quick_action_params) }
          .each do |widget|
            widget.quick_action_params
              .filter { |param_name| command_params.key?(param_name) }
              .each do |param_name|
                widget_params[widget.api_symbol] ||= {}
                widget_params[widget.api_symbol][param_name] = command_params.delete(param_name)
              end
          end

        # The command_params not processed by widgets (e.g. title) should be placed in 'attributes'.
        attributes.merge!(command_params || {})
      end
    end
  end
end

Mutations::WorkItems::Update.prepend_mod
