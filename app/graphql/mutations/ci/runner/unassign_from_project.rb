# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      class UnassignFromProject < BaseMutation
        graphql_name 'RunnerUnassignFromProject'

        include FindsProject

        authorize :admin_runners

        argument :runner_id, ::Types::GlobalIDType[::Ci::Runner],
          required: true,
          description: 'ID of the runner to unassign from the project.'

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the project from which the runner will be unassigned.'

        def resolve(**args)
          project = authorized_find!(args[:project_path])
          runner_id = GitlabSchema.parse_gid(args[:runner_id], expected_type: ::Ci::Runner).model_id
          runner_project = project.runner_projects.find_by_runner_id(runner_id)

          unless runner_project&.runner
            raise_resource_not_available_error! "Runner does not exist or is not assigned to this project"
          end

          result = ::Ci::Runners::UnassignRunnerService.new(runner_project, current_user).execute

          { errors: result.errors }
        end
      end
    end
  end
end
