# frozen_string_literal: true

module Resolvers
  module Projects
    class ForkDetailsResolver < BaseResolver
      type Types::Projects::ForkDetailsType, null: true

      argument :ref, GraphQL::Types::String,
        required: false,
        description: 'Ref of the fork. Default value is HEAD.'

      alias_method :project, :object

      def resolve(**args)
        return unless project.forked?
        return unless authorized_fork_source?

        ::Projects::Forks::Details.new(project, args[:ref])
      end

      private

      def authorized_fork_source?
        Ability.allowed?(current_user, :read_code, project.fork_source)
      end
    end
  end
end
