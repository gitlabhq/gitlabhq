# frozen_string_literal: true

module Mutations
  module Commits
    class Create < BaseMutation
      graphql_name 'CommitCreate'

      include FindsProject
      include Gitlab::InternalEventsTracking

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

      argument :start_sha, GraphQL::Types::String,
        required: false,
        description: 'SHA of the commit to start the new branch from. Mutually exclusive with startBranch.'

      argument :start_project_path, GraphQL::Types::ID,
        required: false,
        description: 'Full path of the project to start the commit from. ' \
          'Must be the project itself or a project it was forked from.'

      argument :message,
        GraphQL::Types::String,
        required: true,
        description: copy_field_description(Types::Repositories::CommitType, :message)

      argument :actions,
        [Types::CommitActionType],
        required: false,
        default_value: [],
        replace_null_with_default: true,
        description: 'Array of action hashes to commit as a batch.'

      argument :allow_empty,
        GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        replace_null_with_default: true,
        description: 'Indicates whether an empty commit can be created. Defaults to `false`.'

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

      validates mutually_exclusive: [:start_branch, :start_sha]

      authorize :push_code
      authorize_granular_token permissions: :push_code, boundary_argument: :project_path,
        boundary_type: :project

      def resolve(project_path:, branch:, message:, **args)
        actions = args[:actions]
        allow_empty = args[:allow_empty]

        project = authorized_find!(project_path)

        if actions.blank? && !allow_empty
          raise Gitlab::Graphql::Errors::ArgumentError,
            'Provide at least one action, or set allowEmpty to true.'
        end

        attributes = {
          commit_message: message,
          branch_name: branch,
          start_branch: args[:start_sha] ? nil : (args[:start_branch] || branch),
          start_sha: args[:start_sha],
          start_project: fetch_start_project(project, args[:start_project_path]),
          actions: actions.map(&:to_h)
        }.compact

        result = ::Files::MultiService.new(project, current_user, attributes).execute

        track_ci_config_creation(project, actions) if result[:status] == :success

        {
          content: actions.pluck(:content), # rubocop:disable CodeReuse/ActiveRecord -- Array#pluck
          commit: (project.repository.commit(result[:result]) if result[:status] == :success),
          commit_pipeline_path: UrlHelpers.new.graphql_etag_pipeline_sha_path(result[:result]),
          errors: Array.wrap(result[:message])
        }
      end

      private

      # Mirrors the REST commits endpoint contract, with one uniform error so
      # an unreadable start project is indistinguishable from a missing one.
      def fetch_start_project(project, full_path)
        return unless full_path

        start_project = find_object(full_path)

        allowed = start_project && Ability.allowed?(current_user, :read_code, start_project) &&
          (start_project == project || project.forked_from?(start_project))

        unless allowed
          raise_resource_not_available_error!(
            'startProjectPath is not the project or a member of its fork network, or you cannot read its code.')
        end

        start_project
      end

      def track_ci_config_creation(project, actions)
        creates_ci_config = actions.any? do |action|
          action[:action].to_s == 'create' && action[:file_path] == project.ci_config_path_or_default
        end

        return unless creates_ci_config

        track_internal_event(
          'create_ci_config_file_from_pipeline_editor',
          user: current_user,
          project: project,
          namespace: project.namespace
        )
      end
    end
  end
end
