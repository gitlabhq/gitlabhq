# frozen_string_literal: true

module Gitlab
  module Ci
    module Runner
      ##
      # Runner Backoff class is an implementation of an exponential backoff
      # used when a runner communicates with GitLab. We typically use it when a
      # runner retries sending a build status after we created a build pending
      # state.
      #
      # Backoff is calculated based on the backoff slot which is always a power
      # of 2:
      #
      #   0s -  3s   duration -> 1   second backoff
      #   4s -  7s   duration -> 2  seconds backoff
      #   8s - 15s   duration -> 4  seconds backoff
      #  16s  - 31s  duration -> 8  seconds backoff
      #  32s - 63s   duration -> 16 seconds backoff
      #  64s - 127s  duration -> 32 seconds backoff
      # 127s - 256s+ duration -> 64 seconds backoff
      #
      # It means that first 15 requests made by a runner will need to respect
      # following backoffs:
      #
      #  0s -> 1 second  backoff (backoff started, slot 0, 2^0 backoff)
      #  1s -> 1 second  backoff
      #  2s -> 1 second  backoff
      #  3s -> 1 seconds backoff
      #                          (slot 1 - 2^1 backoff)
      #  4s -> 2 seconds backoff
      #  6s -> 2 seconds backoff
      #                          (slot 2 - 2^2 backoff)
      #  8s -> 4 seconds backoff
      # 12s -> 4 seconds backoff
      #                          (slot 3 - 2^3 backoff)
      # 16s -> 8 seconds backoff
      # 24s -> 8 seconds backoff
      #                          (slot 4 - 2^4 backoff)
      # 32s -> 16 seconds backoff
      # 48s -> 16 seconds backoff
      #                          (slot 5 - 2^5 backoff)
      # 64s -> 32 seconds backoff
      # 96s -> 32 seconds backoff
      #                          (slot 6 - 2^6 backoff)
      # 128s -> 64 seconds backoff
      #
      # There is a cap on the backoff - it will never exceed 64 seconds.
      #
      class Backoff
        def initialize(started)
          @started = started

          if duration < 0
            raise ArgumentError, 'backoff duration negative'
          end
        end

        def duration
          (Time.current - @started).ceil
        end

        def slot
          return 0 if duration < 2

          Math.log(duration, 2).floor - 1
        end

        def to_seconds
          2**[slot, 6].min
        end
      end
    end
  end
end
