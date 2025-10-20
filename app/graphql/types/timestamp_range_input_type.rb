# frozen_string_literal: true

module Types
  # rubocop:disable Gitlab/BoundedContexts -- not added to Gitlab context for consistency with other generic types
  class TimestampRangeInputType < RangeInputType[::Types::TimeType]
    graphql_name 'TimestampRange'
    description 'A closed, inclusive range of two timestamps'

    def prepare
      # Reject equal timestamps because DB timestamp precision is much higher
      # than what a user can query and may lead to confusion.
      if self[:end] && self[:start] && self[:end] == self[:start]
        raise ::Gitlab::Graphql::Errors::ArgumentError, 'start must be before end'
      end

      super
    end
  end
  # rubocop: enable Gitlab/BoundedContexts
end
