module Gitlab
  module Ci
    class PipelineDuration
      PeriodStruct = Struct.new(:first, :last)
      class Period < SegmentStruct
        def duration
          last - first
        end
      end

      def self.from_builds(builds)
        now = Time.now

        periods = builds.map do |b|
          Period.new(b.started_at || now, b.finished_at || now)
        end

        new(periods)
      end

      attr_reader :duration, :pending_duration

      def initialize(periods)
        process(periods.sort_by(&:first))
      end

      private

      def process(periods)
        merged = process_periods(periods)

        @duration = process_duration(merged)
        @pending_duration = process_pending_duration(merged)
      end

      def process_periods(periods)
        if periods.empty?
          periods
        else
          periods.drop(1).inject([periods.first]) do |result, current|
            merged = try_merge_period(result.last, current)

            if merged
              result[-1] = merged
              result
            else
              result << current
            end
          end
        end
      end

      def try_merge_period(previous, current)
        if current.first <= previous.last
          Period.new(previous.first, [previous.last, current.last].max)
        end
      end

      def process_duration(periods)
        periods.inject(0) do |result, per|
          result + per.duration
        end
      end

      def process_pending_duration(periods)
        return 0 if periods.empty?

        total = periods.last.last - periods.first.first
        total - duration
      end
    end
  end
end
