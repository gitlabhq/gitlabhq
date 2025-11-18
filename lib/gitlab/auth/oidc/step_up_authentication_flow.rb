# frozen_string_literal: true

module Gitlab
  module Auth
    module Oidc
      class StepUpAuthenticationFlow
        STATE_REQUESTED = :requested
        STATE_SUCCEEDED = :succeeded
        STATE_FAILED = :failed
        STATE_EXPIRED = :expired

        attr_reader :session, :provider, :scope

        def initialize(session:, provider:, scope:)
          validate_scope!(scope)
          @session = session
          @provider = provider
          @scope = scope
        end

        def requested?
          state.to_s == STATE_REQUESTED.to_s
        end

        def succeeded?
          return false if expired?

          state.to_s == STATE_SUCCEEDED.to_s
        end

        def failed?
          state.to_s == STATE_FAILED.to_s
        end

        def expired?
          check_and_save_if_step_up_auth_expired!

          state.to_s == STATE_EXPIRED.to_s
        end

        def enabled_by_config?
          ::Gitlab::Auth::Oidc::StepUpAuthentication.enabled_for_provider?(provider_name: provider, scope: scope)
        end

        def evaluate!(oidc_id_token_claims)
          oidc_id_token_claims =
            ::Gitlab::Auth::Oidc::StepUpAuthentication.slice_relevant_id_token_claims(
              oauth_raw_info: oidc_id_token_claims,
              provider: provider,
              scope: scope
            )

          if conditions_fulfilled?(oidc_id_token_claims)
            succeed!(oidc_id_token_claims)
          else
            fail!
          end
        end

        def request!
          update_session_state(STATE_REQUESTED)
        end

        def succeed!(oidc_id_token_claims = nil)
          update_session_state(STATE_SUCCEEDED)
          update_expiration_data(oidc_id_token_claims) if oidc_id_token_claims
        end

        def fail!
          update_session_state(STATE_FAILED)
        end

        # Returns the documentation link for this provider's step-up authentication configuration
        #
        # @return [String, nil] the documentation link URL or nil if not configured
        def documentation_link
          ::Gitlab::Auth::OAuth::Provider
            .config_for(provider.to_s)
            &.dig('step_up_auth', scope.to_s, 'documentation_link')
        end

        def expire!
          update_session_state(STATE_EXPIRED)
        end

        # Checks if this step-up authentication session has expired
        # and automatically transitions to expired state if needed
        #
        # @return [Boolean] true if the session has expired, false otherwise
        def check_and_save_if_step_up_auth_expired!
          return unless provider_scope_session_data

          result = ::Gitlab::Auth::Oidc::StepUpAuthExpirationValidator
                     .validate(provider_scope_session_data)

          # If the session is expired but state is not yet expired, transition to expired
          expire! if result.expired?

          result.expired?
        end

        private

        def state
          provider_scope_session_data&.[]('state').to_s.presence
        end

        def provider_scope_session_data
          omniauth_step_up_auth_session_data&.[](provider.to_s)&.[](scope.to_s)
        end

        def update_session_state(new_state)
          omniauth_step_up_auth_session_data[provider.to_s] ||= {}
          omniauth_step_up_auth_session_data[provider.to_s][scope.to_s] ||= {}
          omniauth_step_up_auth_session_data[provider.to_s][scope.to_s]['state'] = new_state.to_s
        end

        # Updates session with expiration data from OIDC ID token claims
        #
        # @param oidc_id_token_claims [Hash] the OIDC ID token claims containing expiration info
        def update_expiration_data(oidc_id_token_claims)
          return unless oidc_id_token_claims

          expiration_data = extract_expiration_data(oidc_id_token_claims)
          omniauth_step_up_auth_session_data[provider.to_s][scope.to_s].merge!(expiration_data)
        end

        # Extracts expiration data from OIDC ID token claims
        #
        # @param oidc_id_token_claims [Hash] the OIDC ID token claims containing expiration info
        # @return [Hash] expiration data including exp timestamp
        def extract_expiration_data(oidc_id_token_claims)
          exp_timestamp = oidc_id_token_claims['exp']

          return {} unless exp_timestamp.present? && exp_timestamp.is_a?(Numeric)

          {
            'exp_timestamp' => exp_timestamp
          }
        end

        def omniauth_step_up_auth_session_data
          ::Gitlab::Auth::Oidc::StepUpAuthentication.omniauth_step_up_auth_session_data(session)
        end

        def conditions_fulfilled?(oidc_id_token_claims)
          ::Gitlab::Auth::Oidc::StepUpAuthentication
            .conditions_fulfilled?(oauth_extra_metadata: oidc_id_token_claims, provider: provider, scope: scope)
        end

        def validate_scope!(scope)
          return if ::Gitlab::Auth::Oidc::StepUpAuthentication::ALLOWED_SCOPES.include?(scope&.to_sym)

          allowed = ::Gitlab::Auth::Oidc::StepUpAuthentication::ALLOWED_SCOPES
          raise ArgumentError,
            "Invalid scope '#{scope}'. Allowed scopes are: #{allowed.join(', ')}"
        end
      end
    end
  end
end
