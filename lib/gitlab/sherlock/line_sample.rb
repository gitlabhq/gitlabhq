module Gitlab
  module Sherlock
    class LineSample
      attr_reader :duration, :events

      def initialize(duration, events)
        @duration = duration
        @events = events
      end

      def percentage_of(total_duration)
        (duration.to_f / total_duration) * 100.0
      end

      def majority_of?(total_duration)
        percentage_of(total_duration) >= 30
      end
    end
  end
end
