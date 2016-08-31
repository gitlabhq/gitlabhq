module Gitlab
  module Ci
    # The problem this class is trying to solve is finding the total running
    # time amongst all the jobs, excluding retries and pending (queue) time.
    # We could reduce this problem down to finding the union of periods.
    #
    # So each job would be represented as a `Period`, which consists of
    # `Period#first` and `Period#last`. A simple example here would be:
    #
    # * A (1, 3)
    # * B (2, 4)
    # * C (6, 7)
    #
    # Here A begins from 1, and ends to 3. B begins from 2, and ends to 4.
    # C begins from 6, and ends to 7. Visually it could be viewed as:
    #
    #     0  1  2  3  4  5  6  7
    #        AAAAAAA
    #           BBBBBBB
    #                       CCCC
    #
    # The union of A, B, and C would be (1, 4) and (6, 7), therefore the
    # total running time should be:
    #
    #     (4 - 1) + (7 - 6) => 4
    #
    # And the pending (queue) time would be (4, 6) like this: (marked as X)
    #
    #     0  1  2  3  4  5  6  7
    #        AAAAAAA
    #           BBBBBBB
    #                       CCCC
    #                  XXXXX
    #
    # Which could be calculated by having (1, 7) as total time, minus
    # the running time we have above, 4. The full calculation would be:
    #
    #     total = (7 - 1)
    #     duration = (4 - 1) + (7 - 6)
    #     pending = total - duration # 6 - 4 => 2
    #
    # Which the answer to pending would be 2 in this example.
    #
    # The algorithm used here for union would be described as follow.
    # First we make sure that all periods are sorted by `Period#first`.
    # Then we try to merge periods by iterating through the first period
    # to the last period. The goal would be merging all overlapped periods
    # so that in the end all the periods are discrete. When all periods
    # are discrete, we're free to just sum all the periods to get real
    # running time.
    #
    # Here we begin from A, and compare it to B. We could find that
    # before A ends, B already started. That is `B.first <= A.last`
    # that is `2 <= 3` which means A and B are overlapping!
    #
    # When we found that two periods are overlapping, we would need to merge
    # them into a new period and disregard the old periods. To make a new
    # period, we take `A.first` as the new first because remember? we sorted
    # them, so `A.first` must be smaller or equal to `B.first`. And we take
    # `[A.last, B.last].max` as the new last because we want whoever ended
    # later. This could be broken into two cases:
    #
    #     0  1  2  3  4
    #        AAAAAAA
    #           BBBBBBB
    #
    # Or:
    #
    #     0  1  2  3  4
    #        AAAAAAAAAA
    #           BBBB
    #
    # So that we need to take whoever ends later. Back to our example,
    # after merging and discard A and B it could be visually viewed as:
    #
    #     0  1  2  3  4  5  6  7
    #        DDDDDDDDDD
    #                       CCCC
    #
    # Now we could go on and compare the newly created D and the old C.
    # We could figure out that D and C are not overlapping by checking
    # `C.first <= D.last` is `false`. Therefore we need to keep both C
    # and D. The example would end here because there are no more jobs.
    #
    # After having the union of all periods, the rest is simple and
    # described in the beginning. To summarise:
    #
    #     duration = (4 - 1) + (7 - 6)
    #     total = (7 - 1)
    #     pending = total - duration # 6 - 4 => 2
    #
    # Note that the pending time is actually not the final pending time
    # for pipelines, because we still need to accumulate the pending time
    # before the first job (A in this example) even started! That is:
    #
    #     total_pending = pipeline.started_at - pipeline.created_at + pending
    #
    # Would be the final answer. We deal with that in pipeline itself
    # but not here because here we try not to be depending on pipeline
    # and it's trivial enough to get that information.
    class PipelineDuration
      PeriodStruct = Struct.new(:first, :last)
      class Period < PeriodStruct
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
        return periods if periods.empty?

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
