module Gitlab
  module Auth
    ##
    # Metrics and logging for user authentication activity.
    #
    class Activity
      extend Gitlab::Utils::StrongMemoize

      COUNTERS = {
        user_authenticated: 'Counter of total successful authentication events',
        user_unauthenticated: 'Counter of total authentication failures',
        user_not_found: 'Counter of total failed log-ins when user is unknown',
        user_password_invalid: 'Counter of failed log-ins with invalid password',
        user_session_fetched: 'Counter of total sessions fetched',
        user_session_override: 'Counter of manual log-ins and sessions overrides',
        user_signed_out: 'Counter of total user sign out events'
      }.freeze

      def initialize(opts)
        @opts = opts
      end

      def user_authentication_failed!
        self.class.user_unauthenticated_counter.increment

        case @opts[:message]
        when :not_found_in_database
          self.class.user_not_found_counter.increment
        when :invalid
          self.class.user_password_invalid_counter.increment
        end
      end

      def user_authenticated!
        self.class.user_authenticated_counter.increment
      end

      def user_session_fetched!
        self.class.user_session_fetched_counter.increment
      end

      def user_set_manually!
        self.class.user_session_override_counter.increment
      end

      def user_logout!
        self.class.user_signed_out_counter.increment
      end

      class StubCounter
        def initialize(metric)
          Rails.logger.warn("METRIC #{metric}")
        end

        def increment
        end
      end

      COUNTERS.each_pair do |metric, description|
        define_singleton_method("#{metric}_counter") do
          strong_memoize(metric) do
            StubCounter.new(metric)
            # Gitlab::Metrics.counter("gitlab_auth_#{metric}_total", description)
          end
        end
      end
    end
  end
end
