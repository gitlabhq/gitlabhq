# frozen_string_literal: true

module Resolvers
  module Ci
    class AllJobsResolver < BaseResolver
      type ::Types::Ci::JobType.connection_type, null: true

      argument :statuses, [::Types::Ci::JobStatusEnum],
              required: false,
              description: 'Filter jobs by status.'

      def resolve(statuses: nil)
        ::Ci::JobsFinder.new(current_user: current_user, params: { scope: statuses }).execute
      end
    end
  end
end
