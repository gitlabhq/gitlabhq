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
        user_session_override: 'Counter of manual log-ins and sessions overrides',
        user_session_destroyed: 'Counter of total user sessions being destroyed',
        user_two_factor_authenticated: 'Counter of two factor authentications',
        user_blocked: 'Counter of total sign in attempts when user is blocked'
      }.freeze

      def initialize(user, opts)
        @user = user
        @opts = opts
      end

      def user_authentication_failed!
        self.class.user_unauthenticated_counter_increment!

        case @opts[:message]
        when :not_found_in_database
          self.class.user_not_found_counter_increment!
        when :invalid
          self.class.user_password_invalid_counter_increment!
        end

        if @user.present? && @user.blocked?
          self.class.user_blocked_counter_increment!
        end
      end

      def user_authenticated!
        self.class.user_authenticated_counter_increment!
      end

      def user_session_override!
        self.class.user_session_override_counter_increment!

        if @opts[:message] == :two_factor_authenticated
          self.class.user_two_factor_authenticated_counter_increment!
        end
      end

      def user_session_destroyed!
        self.class.user_session_destroyed_counter_increment!
      end

      def self.each_counter
        COUNTERS.each_pair do |metric, description|
          yield "#{metric}_counter", metric, description
        end
      end

      each_counter do |counter, metric, description|
        define_singleton_method(counter) do
          strong_memoize(counter) do
            Gitlab::Metrics.counter("gitlab_auth_#{metric}_total".to_sym, description)
          end
        end

        define_singleton_method("#{counter}_increment!") do
          public_send(counter).increment # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end
