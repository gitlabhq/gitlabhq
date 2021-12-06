# frozen_string_literal: true

module Resolvers
  module Ci
    # NOTE: This class was introduced to allow modifying the meaning of certain values in RunnerStatusEnum
    # while preserving backward compatibility. It can be removed in 15.0 once the API has stabilized.
    class RunnerStatusResolver < BaseResolver
      type Types::Ci::RunnerStatusEnum, null: false

      alias_method :runner, :object

      argument :legacy_mode,
               type: GraphQL::Types::String,
               default_value: '14.5',
               required: false,
               description: 'Compatibility mode. A null value turns off compatibility mode.',
               deprecated: { reason: 'Will be removed in 15.0. From that release onward, the field will behave as if legacyMode is null', milestone: '14.6' }

      def resolve(legacy_mode:, **args)
        runner.status(legacy_mode)
      end
    end
  end
end
