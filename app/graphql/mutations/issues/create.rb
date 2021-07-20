# frozen_string_literal: true

module Mutations
  module Issues
    class Create < BaseMutation
      include FindsProject
      graphql_name 'CreateIssue'

      authorize :create_issue

      include CommonMutationArguments

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'Project full path the issue is associated with.'

      argument :iid, GraphQL::INT_TYPE,
               required: false,
               description: 'The IID (internal ID) of a project issue. Only admins and project owners can modify.'

      argument :title, GraphQL::STRING_TYPE,
               required: true,
               description: copy_field_description(Types::IssueType, :title)

      argument :milestone_id, ::Types::GlobalIDType[::Milestone],
               required: false,
               description: 'The ID of the milestone to assign to the issue. On update milestone will be removed if set to null.'

      argument :labels, [GraphQL::STRING_TYPE],
               required: false,
               description: copy_field_description(Types::IssueType, :labels)

      argument :label_ids, [::Types::GlobalIDType[::Label]],
               required: false,
               description: 'The IDs of labels to be added to the issue.'

      argument :created_at, Types::TimeType,
               required: false,
               description: 'Timestamp when the issue was created. Available only for admins and project owners.'

      argument :merge_request_to_resolve_discussions_of, ::Types::GlobalIDType[::MergeRequest],
               required: false,
               description: 'The IID of a merge request for which to resolve discussions.'

      argument :discussion_to_resolve, GraphQL::STRING_TYPE,
               required: false,
               description: 'The ID of a discussion to resolve. Also pass `merge_request_to_resolve_discussions_of`.'

      argument :assignee_ids, [::Types::GlobalIDType[::User]],
               required: false,
               description: 'The array of user IDs to assign to the issue.'

      field :issue,
            Types::IssueType,
            null: true,
            description: 'The issue after mutation.'

      def ready?(**args)
        if args.slice(*mutually_exclusive_label_args).size > 1
          arg_str = mutually_exclusive_label_args.map { |x| x.to_s.camelize(:lower) }.join(' or ')
          raise Gitlab::Graphql::Errors::ArgumentError, "one and only one of #{arg_str} is required."
        end

        if args[:discussion_to_resolve].present? && args[:merge_request_to_resolve_discussions_of].blank?
          raise Gitlab::Graphql::Errors::ArgumentError,
                'to resolve a discussion please also provide `merge_request_to_resolve_discussions_of` parameter'
        end

        super
      end

      def resolve(project_path:, **attributes)
        project = authorized_find!(project_path)
        params = build_create_issue_params(attributes.merge(author_id: current_user.id))

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])
        issue = ::Issues::CreateService.new(project: project, current_user: current_user, params: params, spam_params: spam_params).execute

        if issue.spam?
          issue.errors.add(:base, 'Spam detected.')
        end

        {
          issue: issue.valid? ? issue : nil,
          errors: errors_on_object(issue)
        }
      end

      private

      def build_create_issue_params(params)
        params[:milestone_id] &&= params[:milestone_id]&.model_id
        params[:assignee_ids] &&= params[:assignee_ids].map { |assignee_id| assignee_id&.model_id }
        params[:label_ids] &&= params[:label_ids].map { |label_id| label_id&.model_id }

        params
      end

      def mutually_exclusive_label_args
        [:labels, :label_ids]
      end
    end
  end
end

Mutations::Issues::Create.prepend_mod_with('Mutations::Issues::Create')
