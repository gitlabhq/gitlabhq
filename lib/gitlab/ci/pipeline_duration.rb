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
          segments[1..-1].inject([segments.first]) do |current, target|
            left, result = insert_segment(current, target)

            if left # left is the latest one
              result << left
            else
              result
            end
          end
        end
      end

      def insert_segment(segments, init)
        segments.inject([init, []]) do |target_result, member|
          target, result = target_result

          if target.nil? # done
            result << member
            [nil, result]
          elsif merged = try_merge_segment(target, member) # overlapped
            [merged, result] # merge and keep finding the hole
          elsif target.last < member.first # found the hole
            result << target << member
            [nil, result]
          else
            result << member
            target_result
          end
        end
      end

      def try_merge_segment(target, member)
        if target.first <= member.last && target.last >= member.first
          Segment.new([target.first, member.first].min,
                      [target.last, member.last].max)
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
