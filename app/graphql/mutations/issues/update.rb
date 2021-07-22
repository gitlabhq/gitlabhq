# frozen_string_literal: true

module Mutations
  module Issues
    class Update < Base
      graphql_name 'UpdateIssue'

      include CommonMutationArguments

      argument :title, GraphQL::Types::String,
               required: false,
               description: copy_field_description(Types::IssueType, :title)

      argument :milestone_id, GraphQL::Types::ID, # rubocop: disable Graphql/IDType
               required: false,
               description: 'The ID of the milestone to assign to the issue. On update milestone will be removed if set to null.'

      argument :add_label_ids, [GraphQL::Types::ID],
               required: false,
               description: 'The IDs of labels to be added to the issue.'

      argument :remove_label_ids, [GraphQL::Types::ID],
               required: false,
               description: 'The IDs of labels to be removed from the issue.'

      argument :state_event, Types::IssueStateEventEnum,
               description: 'Close or reopen an issue.',
               required: false

      def resolve(project_path:, iid:, **args)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])
        ::Issues::UpdateService.new(project: project, current_user: current_user, params: args, spam_params: spam_params).execute(issue)

        {
          issue: issue,
          errors: errors_on_object(issue)
        }
      end
    end
  end
end

Mutations::Issues::Update.prepend_mod_with('Mutations::Issues::Update')
