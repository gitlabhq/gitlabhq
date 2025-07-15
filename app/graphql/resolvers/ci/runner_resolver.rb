# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerResolver < BaseResolver
      type Types::Ci::RunnerType, null: true
      description 'Runner information.'

      argument :id,
        type: ::Types::GlobalIDType[::Ci::Runner],
        required: true,
        description: 'Runner ID.'

      def resolve(id:)
        GitlabSchema.object_from_id(id, expected_type: ::Ci::Runner)
      end
    end
  end
end
