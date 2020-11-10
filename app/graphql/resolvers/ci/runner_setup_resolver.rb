# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerSetupResolver < BaseResolver
      type Types::Ci::RunnerSetupType, null: true

      argument :platform, GraphQL::STRING_TYPE,
        required: true,
        description: 'Platform to generate the instructions for'

      argument :architecture, GraphQL::STRING_TYPE,
        required: true,
        description: 'Architecture to generate the instructions for'

      argument :project_id, ::Types::GlobalIDType[::Project],
        required: false,
        description: 'Project to register the runner for'

      argument :group_id, ::Types::GlobalIDType[::Group],
        required: false,
        description: 'Group to register the runner for'

      def resolve(platform:, architecture:, **args)
        instructions = Gitlab::Ci::RunnerInstructions.new(
          { current_user: current_user, os: platform, arch: architecture }.merge(target_param(args))
        )

        {
          install_instructions: instructions.install_script || other_install_instructions(platform),
          register_instructions: instructions.register_command
        }
      ensure
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'User is not authorized to register a runner for the specified resource!' if instructions.errors.include?('Gitlab::Access::AccessDeniedError')
      end

      private

      def other_install_instructions(platform)
        Gitlab::Ci::RunnerInstructions::OTHER_ENVIRONMENTS[platform.to_sym][:installation_instructions_url]
      end

      def target_param(args)
        project_param(args[:project_id]) || group_param(args[:group_id]) || {}
      end

      def project_param(project_id)
        return unless project_id

        { project: find_object(project_id) }
      end

      def group_param(group_id)
        return unless group_id

        { group: find_object(group_id) }
      end

      def find_object(gid)
        GlobalID::Locator.locate(gid)
      end
    end
  end
end
