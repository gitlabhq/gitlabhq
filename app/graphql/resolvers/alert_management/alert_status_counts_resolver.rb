# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class AlertStatusCountsResolver < BaseResolver
      type Types::AlertManagement::AlertStatusCountsType, null: true

      def resolve(**args)
        ::Gitlab::AlertManagement::AlertStatusCounts.new(context[:current_user], object, args)
      end
    end
  end
end
