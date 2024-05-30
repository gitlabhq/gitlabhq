# frozen_string_literal: true

module Mutations
  module Issues
    class Create < BaseMutation
      graphql_name 'CreateIssue'

      include Mutations::SpamProtection
      include FindsProject
      include CommonMutationArguments

      authorize :create_issue

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Project full path the issue is associated with.'

      argument :iid, GraphQL::Types::Int,
        required: false,
        description: 'IID (internal ID) of a project issue. Only admins and project owners can modify.'

      argument :title, GraphQL::Types::String,
        required: true,
        description: copy_field_description(Types::IssueType, :title)

      argument :milestone_id, ::Types::GlobalIDType[::Milestone],
        required: false,
        description: 'ID of the milestone to assign to the issue. On update milestone will be removed if set to null.'

      argument :labels, [GraphQL::Types::String],
        required: false,
        description: copy_field_description(Types::IssueType, :labels)

      argument :label_ids, [::Types::GlobalIDType[::Label]],
        required: false,
        description: 'IDs of labels to be added to the issue.'

      argument :created_at, Types::TimeType,
        required: false,
        description: 'Timestamp when the issue was created. Available only for admins and project owners.'

      argument :merge_request_to_resolve_discussions_of, ::Types::GlobalIDType[::MergeRequest],
        required: false,
        description: 'IID of a merge request for which to resolve discussions.'

      argument :discussion_to_resolve, GraphQL::Types::String,
        required: false,
        description: 'ID of a discussion to resolve. Also pass `merge_request_to_resolve_discussions_of`.'

      argument :assignee_ids, [::Types::GlobalIDType[::User]],
        required: false,
        description: 'Array of user IDs to assign to the issue.'

      argument :move_before_id, ::Types::GlobalIDType[::Issue],
        required: false,
        description: 'Global ID of issue that should be placed before the current issue.'

      argument :move_after_id, ::Types::GlobalIDType[::Issue],
        required: false,
        description: 'Global ID of issue that should be placed after the current issue.'

      field :issue,
        Types::IssueType,
        null: true,
        description: 'Issue after mutation.'

      validates mutually_exclusive: [:labels, :label_ids]

      def ready?(**args)
        if args[:discussion_to_resolve].present? && args[:merge_request_to_resolve_discussions_of].blank?
          raise Gitlab::Graphql::Errors::ArgumentError,
            'to resolve a discussion please also provide `merge_request_to_resolve_discussions_of` parameter'
        end

        super
      end

      def resolve(project_path:, **attributes)
        project = authorized_find!(project_path)
        params = build_create_issue_params(attributes.merge(author_id: current_user.id), project)
        result = ::Issues::CreateService.new(container: project, current_user: current_user, params: params).execute

        check_spam_action_response!(result[:issue]) if result[:issue]

        {
          issue: result.success? ? result[:issue] : nil,
          errors: result.errors
        }
      end

      private

      # _project argument is unused here, but it is necessary on the EE version of the method
      def build_create_issue_params(params, _project)
        params[:milestone_id] &&= params[:milestone_id]&.model_id
        params[:assignee_ids] &&= params[:assignee_ids].map { |assignee_id| assignee_id&.model_id }
        params[:label_ids] &&= params[:label_ids].map { |label_id| label_id&.model_id }

        if params[:move_before_id].present? || params[:move_after_id].present?
          params[:move_between_ids] = [
            params.delete(:move_before_id)&.model_id,
            params.delete(:move_after_id)&.model_id
          ]
        end

        params
      end
    end
  end
end

Mutations::Issues::Create.prepend_mod_with('Mutations::Issues::Create')
