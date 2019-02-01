# frozen_string_literal: true

module Gitlab
  module Sherlock
    class LineSample
      attr_reader :duration, :events

      # duration - The execution time in milliseconds.
      # events - The amount of events.
      def initialize(duration, events)
        @duration = duration
        @events = events
      end

      # Returns the sample duration percentage relative to the given duration.
      #
      # Example:
      #
      #     sample.duration            # => 150
      #     sample.percentage_of(1500) # => 10.0
      #
      # total_duration - The total duration to compare with.
      #
      # Returns a float
      def percentage_of(total_duration)
        (duration.to_f / total_duration) * 100.0
      end

      # Returns true if the current sample takes up the majority of the given
      # duration.
      #
      # total_duration - The total duration to compare with.
      def majority_of?(total_duration)
        percentage_of(total_duration) >= 30
      end
    end
  end
end
