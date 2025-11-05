# frozen_string_literal: true

module Mutations
  module WorkItems
    class Create < BaseMutation
      graphql_name 'WorkItemCreate'

      include Mutations::SpamProtection
      include FindsNamespace
      include Mutations::WorkItems::SharedArguments
      include Mutations::WorkItems::Widgetable

      description "Creates a work item."

      authorize :create_work_item

      MUTUALLY_EXCLUSIVE_ARGUMENTS_ERROR = 'Please provide either projectPath or namespacePath argument, but not both.'

      def self.authorization_scopes
        super + [:ai_workflows]
      end

      argument :create_source,
        GraphQL::Types::String,
        required: false,
        description: 'Source which triggered the creation of the work item. Used only for tracking purposes.'
      argument :created_at, Types::TimeType,
        required: false,
        description: 'Timestamp when the work item was created. Available only for admins and project owners.'
      argument :crm_contacts_widget,
        ::Types::WorkItems::Widgets::CrmContactsCreateInputType,
        required: false,
        description: 'Input for CRM contacts widget.'
      argument :description,
        GraphQL::Types::String,
        required: false,
        description: copy_field_description(Types::WorkItemType, :description),
        deprecated: { milestone: '16.9', reason: 'use description widget instead' }
      argument :discussions_to_resolve,
        ::Types::WorkItems::ResolveDiscussionsInputType,
        required: false,
        description: 'Information required to resolve discussions in a noteable, when the work item is created.',
        prepare: ->(attributes, _ctx) { attributes.to_h }
      argument :hierarchy_widget,
        ::Types::WorkItems::Widgets::HierarchyCreateInputType,
        required: false,
        description: 'Input for hierarchy widget.'
      argument :labels_widget,
        ::Types::WorkItems::Widgets::LabelsCreateInputType,
        required: false,
        description: 'Input for labels widget.'
      argument :linked_items_widget,
        ::Types::WorkItems::Widgets::LinkedItemsCreateInputType,
        required: false,
        description: 'Input for linked items widget.'
      argument :namespace_path,
        GraphQL::Types::ID,
        required: false,
        description: 'Full path of the namespace(project or group) the work item is created in.'
      argument :project_path,
        GraphQL::Types::ID,
        required: false,
        description: 'Full path of the project the work item is associated with.',
        deprecated: {
          reason: 'Please use namespacePath instead. That will cover for both projects and groups',
          milestone: '15.10'
        }
      argument :start_and_due_date_widget,
        ::Types::WorkItems::Widgets::StartAndDueDateUpdateInputType,
        required: false,
        description: 'Input for start and due date widget.'
      argument :title,
        GraphQL::Types::String,
        required: true,
        description: copy_field_description(Types::WorkItemType, :title)
      argument :work_item_type_id,
        ::Types::GlobalIDType[::WorkItems::Type],
        required: true,
        description: 'Global ID of a work item type.'

      field :work_item,
        ::Types::WorkItemType,
        null: true, scopes: [:api, :ai_workflows],
        description: 'Created work item.'

      field :errors, [GraphQL::Types::String],
        null: false,
        scopes: [:api, :ai_workflows],
        description: 'Errors encountered during the mutation.'

      def ready?(**args)
        if args.slice(:project_path, :namespace_path)&.length != 1
          raise Gitlab::Graphql::Errors::ArgumentError, MUTUALLY_EXCLUSIVE_ARGUMENTS_ERROR
        end

        super
      end

      def resolve(project_path: nil, namespace_path: nil, **attributes)
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/578961')

        # temporary change to make this optional param a no-op until https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210502
        # which introduces handling of this param at the service layer.
        # adding the param in advance for multi version compatibility purposes
        # implemented to prevent an unknown attribute error
        attributes.delete(:create_source)

        container_path = project_path || namespace_path
        container = authorized_find!(container_path)
        params = params_with_work_item_type(attributes).merge(author_id: current_user.id,
          scope_validator: context[:scope_validator])
        params = params_with_resolve_discussion_params(params)
        type = params[:work_item_type]
        raise_resource_not_available_error! unless type

        check_feature_available!(container, type, params)
        widget_params = extract_widget_params!(type, params, container)

        create_result = ::WorkItems::CreateService.new(
          container: container,
          current_user: current_user,
          params: params,
          widget_params: widget_params
        ).execute

        check_spam_action_response!(create_result[:work_item]) if create_result[:work_item]

        {
          work_item: create_result.success? ? create_result[:work_item] : nil,
          errors: create_result.errors
        }
      end

      private

      # Overridden on EE
      def check_feature_available!(container, type, params)
        return unless container.is_a?(::Group)

        if params[:merge_request_to_resolve_discussions_object]
          raise Gitlab::Graphql::Errors::ArgumentError,
            _('Only project level work items can be created to resolve noteable discussions')
        end

        return if ::WorkItems::Type.allowed_group_level_types(container).include?(type.base_type)

        raise_resource_not_available_error!
      end

      def params_with_resolve_discussion_params(attributes)
        discussion_attributes = attributes.delete(:discussions_to_resolve)
        return attributes if discussion_attributes.blank?

        noteable = discussion_attributes[:noteable_id].find
        unless noteable.is_a?(::MergeRequest)
          raise Gitlab::Graphql::Errors::ArgumentError,
            _('Only Merge Requests are allowed as a noteable to resolve discussions of at the moment.')
        end

        raise_resource_not_available_error! unless current_user.can?(:resolve_note, noteable)

        attributes[:discussion_to_resolve] = discussion_attributes[:discussion_id]
        attributes[:merge_request_to_resolve_discussions_object] = noteable
        attributes
      end

      def params_with_work_item_type(attributes)
        work_item_type_id = attributes.delete(:work_item_type_id)&.model_id
        work_item_type = ::WorkItems::Type.find_by_id(work_item_type_id)

        attributes[:work_item_type] = work_item_type

        attributes
      end
    end
  end
end

Mutations::WorkItems::Create.prepend_mod
