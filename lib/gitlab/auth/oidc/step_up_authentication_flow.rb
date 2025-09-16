# frozen_string_literal: true

module Gitlab
  module Auth
    module Oidc
      class StepUpAuthenticationFlow
        STATE_REQUESTED = :requested
        STATE_SUCCEEDED = :succeeded
        STATE_FAILED = :failed

        attr_reader :session, :provider, :scope

        def initialize(session:, provider:, scope:)
          @session = session
          @provider = provider
          @scope = scope
        end

        def requested?
          state.to_s == STATE_REQUESTED.to_s
        end

        def succeeded?
          state.to_s == STATE_SUCCEEDED.to_s
        end

        def failed?
          state.to_s == STATE_FAILED.to_s
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
            succeed!
          else
            fail!
          end
        end

        def request!
          update_session_state(STATE_REQUESTED)
        end

        def succeed!
          update_session_state(STATE_SUCCEEDED)
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

        def omniauth_step_up_auth_session_data
          ::Gitlab::Auth::Oidc::StepUpAuthentication.omniauth_step_up_auth_session_data(session)
        end

        def conditions_fulfilled?(oidc_id_token_claims)
          ::Gitlab::Auth::Oidc::StepUpAuthentication
            .conditions_fulfilled?(oauth_extra_metadata: oidc_id_token_claims, provider: provider, scope: scope)
        end
      end
    end
  end
end
