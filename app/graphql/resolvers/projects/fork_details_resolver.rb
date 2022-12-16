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

        ::Projects::Forks::DivergenceCounts.new(project, args[:ref]).counts
      end
    end
  end
end
