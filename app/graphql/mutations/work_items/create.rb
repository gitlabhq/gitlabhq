# frozen_string_literal: true

module Mutations
  module WorkItems
    class Create < BaseMutation
      graphql_name 'WorkItemCreate'

      include Mutations::SpamProtection
      include FindsProject
      include Mutations::WorkItems::Widgetable

      description "Creates a work item. Available only when feature flag `work_items` is enabled."

      authorize :create_work_item

      argument :description, GraphQL::Types::String,
               required: false,
               description: copy_field_description(Types::WorkItemType, :description)
      argument :hierarchy_widget, ::Types::WorkItems::Widgets::HierarchyCreateInputType,
               required: false,
               description: 'Input for hierarchy widget.'
      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'Full path of the project the work item is associated with.'
      argument :title, GraphQL::Types::String,
               required: true,
               description: copy_field_description(Types::WorkItemType, :title)
      argument :work_item_type_id, ::Types::GlobalIDType[::WorkItems::Type],
               required: true,
               description: 'Global ID of a work item type.'

      field :work_item, Types::WorkItemType,
            null: true,
            description: 'Created work item.'

      def resolve(project_path:, **attributes)
        project = authorized_find!(project_path)

        unless project.work_items_feature_flag_enabled?
          return { errors: ['`work_items` feature flag disabled for this project'] }
        end

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])
        params = global_id_compatibility_params(attributes).merge(author_id: current_user.id)
        type = ::WorkItems::Type.find(attributes[:work_item_type_id])
        widget_params = extract_widget_params!(type, params)

        create_result = ::WorkItems::CreateService.new(
          project: project,
          current_user: current_user,
          params: params,
          spam_params: spam_params,
          widget_params: widget_params
        ).execute

        check_spam_action_response!(create_result[:work_item]) if create_result[:work_item]

        {
          work_item: create_result.success? ? create_result[:work_item] : nil,
          errors: create_result.errors
        }
      end

      private

      def global_id_compatibility_params(params)
        params[:work_item_type_id] = params[:work_item_type_id]&.model_id

        params
      end
    end
  end
end
