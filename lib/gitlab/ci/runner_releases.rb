# frozen_string_literal: true

module Gitlab
  module Ci
    class RunnerReleases
      include Singleton

      RELEASES_VALIDITY_PERIOD = 1.day
      RELEASES_VALIDITY_AFTER_ERROR_PERIOD = 5.seconds

      INITIAL_BACKOFF = 5.seconds
      MAX_BACKOFF = 1.hour
      BACKOFF_GROWTH_FACTOR = 2.0

      def initialize
        reset!
      end

      # Returns a sorted list of the publicly available GitLab Runner releases
      #
      def releases
        return @releases unless Time.now.utc >= @expire_time

        @releases = fetch_new_releases
      end

      def reset!
        @expire_time = Time.now.utc
        @releases = nil
        @backoff_count = 0
      end

      private

      def fetch_new_releases
        response = Gitlab::HTTP.try_get(::Gitlab::CurrentSettings.current_application_settings.public_runner_releases_url)

        releases = response.success? ? extract_releases(response) : nil
      ensure
        @expire_time = (releases ? RELEASES_VALIDITY_PERIOD : next_backoff).from_now
      end

      def extract_releases(response)
        response.parsed_response.map { |release| parse_runner_release(release) }.sort!
      end

      def parse_runner_release(release)
        ::Gitlab::VersionInfo.parse(release['name'], parse_suffix: true)
      end

      def next_backoff
        return MAX_BACKOFF if @backoff_count >= 11 # optimization to prevent expensive exponentiation and possible overflows

        backoff = (INITIAL_BACKOFF * (BACKOFF_GROWTH_FACTOR**@backoff_count))
          .clamp(INITIAL_BACKOFF, MAX_BACKOFF)
          .seconds
        @backoff_count += 1

        backoff
      end
    end
  end
end
