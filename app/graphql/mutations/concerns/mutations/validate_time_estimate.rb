# frozen_string_literal: true

module Mutations
  module ValidateTimeEstimate
    private

    def validate_time_estimate(time_estimate)
      return unless time_estimate

      parsed_time_estimate = Gitlab::TimeTrackingFormatter.parse(time_estimate, keep_zero: true)

      if parsed_time_estimate.nil?
        raise Gitlab::Graphql::Errors::ArgumentError,
          'timeEstimate must be formatted correctly, for example `1h 30m`'
      elsif parsed_time_estimate < 0
        raise Gitlab::Graphql::Errors::ArgumentError,
          'timeEstimate must be greater than or equal to zero. ' \
            'Remember that every new timeEstimate overwrites the previous value.'
      end
    end
  end
end
