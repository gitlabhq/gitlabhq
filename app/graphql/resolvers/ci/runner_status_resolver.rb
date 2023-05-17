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
               default_value: nil,
               required: false,
               description: 'No-op, left for compatibility.',
               deprecated: {
                 reason: 'Will be removed in 17.0',
                 milestone: '15.0'
               }

      def resolve(**args)
        runner.status
      end
    end
  end
end
