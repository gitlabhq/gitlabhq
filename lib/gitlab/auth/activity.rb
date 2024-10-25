# frozen_string_literal: true

module Gitlab
  module Auth
    ##
    # Metrics and logging for user authentication activity.
    #
    class Activity
      extend Gitlab::Utils::StrongMemoize

      COUNTERS = {
        user_authenticated: 'Counter of successful authentication events',
        user_unauthenticated: 'Counter of authentication failures',
        user_not_found: 'Counter of failed log-ins when user is unknown',
        user_password_invalid: 'Counter of failed log-ins with invalid password',
        user_session_override: 'Counter of manual log-ins and sessions overrides',
        user_session_destroyed: 'Counter of user sessions being destroyed',
        user_two_factor_authenticated: 'Counter of two factor authentications',
        user_sessionless_authentication: 'Counter of sessionless authentications',
        user_blocked: 'Counter of sign in attempts when user is blocked',
        user_csrf_token_invalid: 'Counter of CSRF token validation failures'
      }.freeze

      def initialize(opts)
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
      end

      def user_authenticated!
        self.class.user_authenticated_counter_increment!

        case @opts[:message]
        when :two_factor_authenticated
          self.class.user_two_factor_authenticated_counter_increment!
        end
      end

      def user_session_override!
        self.class.user_session_override_counter_increment!

        case @opts[:message]
        when :sessionless_sign_in
          self.class.user_sessionless_authentication_counter_increment!
        end
      end

      def user_blocked!
        self.class.user_blocked_counter_increment!
      end

      def user_session_destroyed!
        self.class.user_session_destroyed_counter_increment!
      end

      def user_csrf_token_mismatch!
        controller = @opts[:controller]
        controller_label = controller.class.name
        controller_label = 'other' unless controller_label == 'GraphqlController'

        session = controller.try(:request).try(:session)
        user_auth_type_label = session.try(:loaded?) ? 'session' : 'other'

        self.class.user_csrf_token_invalid_counter
          .increment(controller: controller_label, auth: user_auth_type_label)
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
