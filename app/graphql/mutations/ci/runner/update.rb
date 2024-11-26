# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      class Update < BaseMutation
        graphql_name 'RunnerUpdate'

        authorize :update_runner

        include Mutations::Ci::Runner::CommonMutationArguments

        RunnerID = ::Types::GlobalIDType[::Ci::Runner]

        argument :id, RunnerID,
          required: true,
          description: 'ID of the runner to update.'

        argument :active, GraphQL::Types::Boolean,
          required: false,
          description: 'Indicates the runner is allowed to receive jobs.',
          deprecated: { reason: :renamed, replacement: 'paused', milestone: '14.8' }

        argument :associated_projects, [::Types::GlobalIDType[::Project]],
          required: false,
          description: 'Projects associated with the runner. Available only for project runners.',
          prepare: ->(global_ids, _ctx) { global_ids&.filter_map { |gid| gid.model_id.to_i } }

        field :runner,
          Types::Ci::RunnerType,
          null: true,
          description: 'Runner after mutation.'

        def resolve(id:, **runner_attrs)
          runner = authorized_find!(id: id)

          associated_projects_ids = runner_attrs.delete(:associated_projects)

          response = { runner: runner, errors: [] }
          ::Ci::Runner.transaction do
            associate_runner_projects(response, runner, associated_projects_ids) unless associated_projects_ids.nil?
            update_runner(response, runner, runner_attrs)
          end

          response
        end

        private

        def associate_runner_projects(response, runner, associated_project_ids)
          unless runner.project_type?
            raise Gitlab::Graphql::Errors::ArgumentError,
              "associatedProjects must not be specified for '#{runner.runner_type}' scope"
          end

          result = ::Ci::Runners::SetRunnerAssociatedProjectsService.new(
            runner: runner,
            current_user: current_user,
            project_ids: associated_project_ids
          ).execute
          return if result.success?

          response[:runner] = nil
          response[:errors] = result.errors
          raise ActiveRecord::Rollback
        end

        def update_runner(response, runner, attrs)
          result = ::Ci::Runners::UpdateRunnerService.new(current_user, runner).execute(attrs)
          return if result.success?

          response[:runner] = nil
          response[:errors] = result.errors
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end

Mutations::Ci::Runner::Update.prepend_mod
