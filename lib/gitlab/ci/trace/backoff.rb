# frozen_string_literal: true

module Gitlab
  module Ci
    class Trace
      ##
      # Trace::Backoff class is responsible for calculating a backoff value
      # for when to be able to retry archiving a build's trace
      #
      # Because we're updating `last_archival_attempt_at` timestamp with every
      # failed archival attempt, we need to be sure that sum of the backoff values
      # for 1..MAX_ATTEMPTS is under 7 days(CHUNK_REDIS_TTL).
      #
      class Backoff
        include Gitlab::Utils::StrongMemoize

        MAX_JITTER_VALUE = 4

        attr_reader :archival_attempts

        def initialize(archival_attempts)
          @archival_attempts = archival_attempts
        end

        def value
          (((chunks_ttl / (3.5 * max_attempts)) * archival_attempts) / 1.hour).hours
        end

        # This formula generates an increasing delay between executions
        # 9.6, 19.2, 28.8, 38.4, 48.0 + a random amount of time to
        # change the order of execution for the jobs.
        # With maximum value for each call to rand(4), this sums up to 6.8 days
        # and with minimum values is 6 days.
        #
        def value_with_jitter
          value + jitter
        end

        private

        def jitter
          rand(MAX_JITTER_VALUE).hours
        end

        def chunks_ttl
          ::Ci::BuildTraceChunks::RedisBase::CHUNK_REDIS_TTL
        end

        def max_attempts
          ::Ci::BuildTraceMetadata::MAX_ATTEMPTS
        end
      end
    end
  end
end
