# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      class Create < BaseMutation
        graphql_name 'RunnerCreate'

        authorize :create_runner

        include Mutations::Ci::Runner::CommonMutationArguments

        argument :runner_type, ::Types::Ci::RunnerTypeEnum,
          required: true,
          description: 'Type of the runner to create.'

        argument :group_id, ::Types::GlobalIDType[Group],
          required: false,
          description: 'Global ID of the group that the runner is created in (valid only for group runner).'

        argument :project_id, ::Types::GlobalIDType[Project],
          required: false,
          description: 'Global ID of the project that the runner is created in (valid only for project runner).'

        field :runner,
          Types::Ci::RunnerType,
          null: true,
          description: 'Runner after mutation.'

        def ready?(**args)
          case args[:runner_type]
          when 'group_type'
            raise Gitlab::Graphql::Errors::ArgumentError, '`group_id` is missing' unless args[:group_id].present?
          when 'project_type'
            raise Gitlab::Graphql::Errors::ArgumentError, '`project_id` is missing' unless args[:project_id].present?
          end

          parse_gid(**args)

          super
        end

        def resolve(**args)
          case args[:runner_type]
          when 'group_type', 'project_type'
            args[:scope] = authorized_find!(**args)
            args.except!(:group_id, :project_id)
          else
            raise_resource_not_available_error! unless current_user.can?(:create_instance_runner)
          end

          response = { runner: nil, errors: [] }
          result = ::Ci::Runners::CreateRunnerService.new(user: current_user, params: args).execute

          if result.success?
            response[:runner] = result.payload[:runner]
          else
            response[:errors] = result.errors
          end

          response
        end

        private

        def find_object(**args)
          obj = parse_gid(**args)

          GitlabSchema.find_by_gid(obj) if obj
        end

        def parse_gid(runner_type:, **args)
          case runner_type
          when 'group_type'
            GitlabSchema.parse_gid(args[:group_id], expected_type: ::Group)
          when 'project_type'
            GitlabSchema.parse_gid(args[:project_id], expected_type: ::Project)
          end
        end
      end
    end
  end
end

Mutations::Ci::Runner::Create.prepend_mod
