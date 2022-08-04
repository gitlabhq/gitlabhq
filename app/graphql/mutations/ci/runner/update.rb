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

        field :runner,
              Types::Ci::RunnerType,
              null: true,
              description: 'Runner after mutation.'

        def resolve(id:, **runner_attrs)
          runner = authorized_find!(id)

          unless ::Ci::Runners::UpdateRunnerService.new(runner).update(runner_attrs)
            return { runner: nil, errors: runner.errors.full_messages }
          end

          { runner: runner, errors: [] }
        end

        def find_object(id)
          GitlabSchema.find_by_gid(id)
        end
      end
    end
  end
end

Mutations::Ci::Runner::Update.prepend_mod_with('Mutations::Ci::Runner::Update')
