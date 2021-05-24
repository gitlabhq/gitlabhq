# frozen_string_literal: true

module Mutations
  module Commits
    class Create < BaseMutation
      include FindsProject

      class UrlHelpers
        include GitlabRoutingHelper
        include Gitlab::Routing
      end

      graphql_name 'CommitCreate'

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'Project full path the branch is associated with.'

      argument :branch, GraphQL::STRING_TYPE,
               required: true,
               description: 'Name of the branch to commit into, it can be a new branch.'

      argument :start_branch, GraphQL::STRING_TYPE,
               required: false,
               description: 'If on a new branch, name of the original branch.'

      argument :message,
               GraphQL::STRING_TYPE,
               required: true,
               description: copy_field_description(Types::CommitType, :message)

      argument :actions,
               [Types::CommitActionType],
               required: true,
               description: 'Array of action hashes to commit as a batch.'

      field :commit_pipeline_path,
            GraphQL::STRING_TYPE,
            null: true,
            description: "ETag path for the commit's pipeline."

      field :commit,
            Types::CommitType,
            null: true,
            description: 'The commit after mutation.'

      field :content,
            [GraphQL::STRING_TYPE],
            null: true,
            description: 'Contents of the commit.'

      authorize :push_code

      def resolve(project_path:, branch:, message:, actions:, **args)
        project = authorized_find!(project_path)

        attributes = {
          commit_message: message,
          branch_name: branch,
          start_branch: args[:start_branch] || branch,
          actions: actions.map { |action| action.to_h }
        }

        result = ::Files::MultiService.new(project, current_user, attributes).execute

        {
          content: actions.pluck(:content),  # rubocop:disable CodeReuse/ActiveRecord because actions is an Array, not a Relation
          commit: (project.repository.commit(result[:result]) if result[:status] == :success),
          commit_pipeline_path: UrlHelpers.new.graphql_etag_pipeline_sha_path(result[:result]),
          errors: Array.wrap(result[:message])
        }
      end
    end
  end
end
