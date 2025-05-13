# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      class AssignToProject < BaseMutation
        graphql_name 'RunnerAssignToProject'

        authorize :assign_runner

        argument :runner_id, ::Types::GlobalIDType[::Ci::Runner],
          required: true,
          description: 'ID of the runner to assign to the project .'

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the project to which the runner will be assigned.'

        def resolve(**args)
          project, runner = find_project_and_runner!(args)
          result = ::Ci::Runners::AssignRunnerService.new(runner, project, current_user).execute

          { errors: result.errors }
        end

        def find_project_and_runner!(args)
          project = ::Project.find_by_full_path(args[:project_path])
          raise_resource_not_available_error! unless project

          runner = authorized_find!(id: args[:runner_id])
          raise_resource_not_available_error!("Runner is not a project runner") unless runner.project_type?

          [project, runner]
        end
      end
    end
  end
end
