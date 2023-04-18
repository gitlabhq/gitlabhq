# frozen_string_literal: true

module Resolvers
  module Ci
    # NOTE: This class was introduced to allow modifying the meaning of certain values in RunnerStatusEnum
    # while preserving backward compatibility. It can be removed in 17.0 after being deprecated
    # and made a no-op in %16.0 (legacy_mode will be hard-coded to nil).
    class RunnerStatusResolver < BaseResolver
      type Types::Ci::RunnerStatusEnum, null: false

      alias_method :runner, :object

      argument :legacy_mode,
               type: GraphQL::Types::String,
               default_value: '14.5',
               required: false,
               description: 'Compatibility mode. A null value turns off compatibility mode.',
               deprecated: {
                 reason: 'Will be removed in 17.0. In GitLab 16.0 and later, ' \
                         'the field will act as if `legacyMode` is null',
                 milestone: '15.0'
               }

      def resolve(legacy_mode:, **args)
        legacy_mode = nil if Feature.enabled?(:disable_runner_graphql_legacy_mode)

        runner.status(legacy_mode)
      end
    end
  end
end
