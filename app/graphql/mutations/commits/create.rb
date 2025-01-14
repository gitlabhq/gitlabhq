# frozen_string_literal: true

module Mutations
  module Commits
    class Create < BaseMutation
      graphql_name 'CommitCreate'

      include FindsProject

      class UrlHelpers
        include GitlabRoutingHelper
        include Gitlab::Routing
      end

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Project full path the branch is associated with.'

      argument :branch, GraphQL::Types::String,
        required: true,
        description: 'Name of the branch to commit into, it can be a new branch.'

      argument :start_branch, GraphQL::Types::String,
        required: false,
        description: 'If on a new branch, name of the original branch.'

      argument :message,
        GraphQL::Types::String,
        required: true,
        description: copy_field_description(Types::Repositories::CommitType, :message)

      argument :actions,
        [Types::CommitActionType],
        required: true,
        description: 'Array of action hashes to commit as a batch.'

      field :commit_pipeline_path,
        GraphQL::Types::String,
        null: true,
        description: "ETag path for the commit's pipeline."

      field :commit,
        Types::Repositories::CommitType,
        null: true,
        description: 'Commit after mutation.'

      field :content,
        [GraphQL::Types::String],
        null: true,
        description: 'Contents of the commit.'

      authorize :push_code

      def resolve(project_path:, branch:, message:, actions:, **args)
        project = authorized_find!(project_path)

        attributes = {
          commit_message: message,
          branch_name: branch,
          start_branch: args[:start_branch] || branch,
          actions: actions.map(&:to_h)
        }

        result = ::Files::MultiService.new(project, current_user, attributes).execute

        {
          content: actions.pluck(:content), # rubocop:disable CodeReuse/ActiveRecord -- Array#pluck
          commit: (project.repository.commit(result[:result]) if result[:status] == :success),
          commit_pipeline_path: UrlHelpers.new.graphql_etag_pipeline_sha_path(result[:result]),
          errors: Array.wrap(result[:message])
        }
      end
    end
  end
end
