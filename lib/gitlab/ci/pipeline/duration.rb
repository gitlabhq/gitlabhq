# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      # # Introduction - total running time
      #
      # The problem this module is trying to solve is finding the total running
      # time amongst all the jobs, excluding retries and pending (queue) time.
      # We could reduce this problem down to finding the union of periods.
      #
      # So each job would be represented as a `Period`, which consists of
      # `Period#first` as when the job started and `Period#last` as when the
      # job was finished. A simple example here would be:
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
      # # The Algorithm
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
      # After having the union of all periods, we just need to sum the length
      # of all periods to get total time.
      #
      #     (4 - 1) + (7 - 6) => 4
      #
      # That is 4 is the answer in the example.
      module Duration
        extend self

        STATUSES = %w[success failed running canceled].freeze

        Period = Struct.new(:first, :last) do
          def duration
            last - first
          end
        end

        def from_pipeline(pipeline)
          builds =
            self_and_downstreams_builds_of_pipeline(pipeline)

          from_builds(builds)
        end

        private

        def from_builds(builds)
          now = Time.now

          periods = builds.map do |b|
            Period.new(b.started_at, b.finished_at || now)
          end

          from_periods(periods)
        end

        # periods should be sorted by `first`
        def from_periods(periods)
          process_duration(process_periods(periods))
        end

        def process_periods(periods)
          return periods if periods.empty?

          periods.drop(1).inject([periods.first]) do |result, current|
            previous = result.last

            if overlap?(previous, current)
              result[-1] = merge(previous, current)
              result
            else
              result << current
            end
          end
        end

        def overlap?(previous, current)
          current.first <= previous.last
        end

        def merge(previous, current)
          Period.new(previous.first, [previous.last, current.last].max)
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def self_and_downstreams_builds_of_pipeline(pipeline)
          ::Ci::Build
            .select(:id, :type, :started_at, :finished_at)
            .in_pipelines(
              pipeline.self_and_downstreams.select(:id)
            )
            .with_status(STATUSES)
            .latest
            .where.not(started_at: nil)
            .order(:started_at)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def process_duration(periods)
          periods.sum(&:duration)
        end
      end
    end
  end
end
