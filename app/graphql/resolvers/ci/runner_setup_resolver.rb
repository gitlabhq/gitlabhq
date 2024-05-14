# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerSetupResolver < BaseResolver
      ACCESS_DENIED = 'User is not authorized to register a runner for the specified resource!'

      type Types::Ci::RunnerSetupType, null: true
      description 'Runner setup instructions.'

      argument :platform,
        type: GraphQL::Types::String,
        required: true,
        description: 'Platform to generate the instructions for.'

      argument :architecture,
        type: GraphQL::Types::String,
        required: true,
        description: 'Architecture to generate the instructions for.'

      argument :project_id,
        type: ::Types::GlobalIDType[::Project],
        required: false,
        deprecated: { reason: 'No longer used', milestone: '13.11' },
        description: 'Project to register the runner for.'

      argument :group_id,
        type: ::Types::GlobalIDType[::Group],
        required: false,
        deprecated: { reason: 'No longer used', milestone: '13.11' },
        description: 'Group to register the runner for.'

      def resolve(platform:, architecture:, **args)
        instructions = Gitlab::Ci::RunnerInstructions.new(
          os: platform,
          arch: architecture
        )

        {
          install_instructions: instructions.install_script || other_install_instructions(platform),
          register_instructions: instructions.register_command
        }
      ensure
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, ACCESS_DENIED if access_denied?(instructions)
      end

      private

      def access_denied?(instructions)
        instructions.errors.include?('Gitlab::Access::AccessDeniedError')
      end

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
