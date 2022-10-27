# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      class Update < BaseMutation
        graphql_name 'RunnerUpdate'

        authorize :update_runner

        RunnerID = ::Types::GlobalIDType[::Ci::Runner]

        argument :id, RunnerID,
                 required: true,
                 description: 'ID of the runner to update.'

        argument :description, GraphQL::Types::String,
                 required: false,
                 description: 'Description of the runner.'

        argument :maintenance_note, GraphQL::Types::String,
                 required: false,
                 description: 'Runner\'s maintenance notes.'

        argument :maximum_timeout, GraphQL::Types::Int,
                 required: false,
                 description: 'Maximum timeout (in seconds) for jobs processed by the runner.'

        argument :access_level, ::Types::Ci::RunnerAccessLevelEnum,
                 required: false,
                 description: 'Access level of the runner.'

        argument :active, GraphQL::Types::Boolean,
                 required: false,
                 description: 'Indicates the runner is allowed to receive jobs.',
                 deprecated: { reason: :renamed, replacement: 'paused', milestone: '14.8' }

        argument :paused, GraphQL::Types::Boolean,
                 required: false,
                 description: 'Indicates the runner is not allowed to receive jobs.'

        argument :locked, GraphQL::Types::Boolean,
                  required: false,
                  description: 'Indicates the runner is locked.'

        argument :run_untagged, GraphQL::Types::Boolean,
                 required: false,
                 description: 'Indicates the runner is able to run untagged jobs.'

        argument :tag_list, [GraphQL::Types::String],
                 required: false,
                 description: 'Tags associated with the runner.'

        argument :associated_projects, [::Types::GlobalIDType[::Project]],
                 required: false,
                 description: 'Projects associated with the runner. Available only for project runners.',
                 prepare: -> (global_ids, ctx) { global_ids&.filter_map { |gid| gid.model_id.to_i } }

        field :runner,
              Types::Ci::RunnerType,
              null: true,
              description: 'Runner after mutation.'

        def resolve(id:, **runner_attrs)
          runner = authorized_find!(id)

          associated_projects_ids = runner_attrs.delete(:associated_projects)

          response = { runner: runner, errors: [] }
          ::Ci::Runner.transaction do
            associate_runner_projects(response, runner, associated_projects_ids) unless associated_projects_ids.nil?
            update_runner(response, runner, runner_attrs)
          end

          response
        end

        def find_object(id)
          GitlabSchema.find_by_gid(id)
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
          result = ::Ci::Runners::UpdateRunnerService.new(runner).execute(attrs)
          return if result.success?

          response[:runner] = nil
          response[:errors] = result.errors
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end

Mutations::Ci::Runner::Update.prepend_mod_with('Mutations::Ci::Runner::Update')
