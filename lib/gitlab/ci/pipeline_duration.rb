module Gitlab
  module Ci
    class PipelineDuration
      SegmentStruct = Struct.new(:first, :last)
      class Segment < SegmentStruct
        def duration
          last - first
        end
      end

      def self.from_builds(builds)
        now = Time.now

        segments = builds.map do |b|
          Segment.new(b.started_at || now, b.finished_at || now)
        end

        new(segments)
      end

      attr_reader :duration, :pending_duration

      def initialize(segments)
        process(segments.sort_by(&:first))
      end

      private

      def process(segments)
        merged = process_segments(segments)

        @duration = process_duration(merged)
        @pending_duration = process_pending_duration(merged, @duration)
      end

      def process_segments(segments)
        if segments.empty?
          segments
        else
          segments.drop(1).inject([segments.first]) do |result, current|
            merged = try_merge_segment(result.last, current)

            if merged
              result[-1] = merged
              result
            else
              result << current
            end
          end
        end
      end

      def try_merge_segment(previous, current)
        if current.first <= previous.last
          Segment.new(previous.first, [previous.last, current.last].max)
        end
      end

      def process_duration(segments)
        segments.inject(0) do |result, seg|
          result + seg.duration
        end
      end

      def process_pending_duration(segments, duration)
        return 0 if segments.empty?

        total = segments.last.last - segments.first.first
        total - duration
      end
    end
  end
end
