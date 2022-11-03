# frozen_string_literal: true

module Resolvers
  module IncidentManagement
    class TimelineEventTagsResolver < BaseResolver
      include LooksAhead

      type ::Types::IncidentManagement::TimelineEventTagType.connection_type, null: true

      def resolve(**args)
        apply_lookahead(::IncidentManagement::TimelineEventTagsFinder.new(current_user, object, args).execute)
      end
    end
  end
end
