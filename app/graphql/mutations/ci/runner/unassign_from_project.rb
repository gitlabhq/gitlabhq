# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      class UnassignFromProject < BaseMutation
        graphql_name 'RunnerUnassignFromProject'

        authorize :unassign_runner

        argument :runner_id, ::Types::GlobalIDType[::Ci::Runner],
          required: true,
          description: 'ID of the runner to unassign from the project.'

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the project from which the runner will be unassigned.'

        def resolve(**args)
          runner_project = find_object(**args.slice(:runner_id, :project_path))
          raise_resource_not_available_error! unless runner_project

          result = ::Ci::Runners::UnassignRunnerService.new(runner_project, current_user).execute

          { errors: result.errors }
        end

        private

        def find_object(runner_id:, project_path:)
          project = Project.find_by_full_path(project_path)
          runner_id = GitlabSchema.parse_gid(runner_id, expected_type: ::Ci::Runner).model_id
          return unless project

          project.runner_projects.find_by_runner_id(runner_id)
        end
      end
    end
  end
end
