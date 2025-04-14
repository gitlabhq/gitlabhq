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

        def rejected?
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

        private

        def state
          provider_scope_session_data&.[]('state').to_s.presence
        end

        def provider_scope_session_data
          session.dig('omniauth_step_up_auth', provider.to_s, scope.to_s)
        end

        def update_session_state(new_state)
          session['omniauth_step_up_auth'] ||= {}
          session['omniauth_step_up_auth'][provider.to_s] ||= {}
          session['omniauth_step_up_auth'][provider.to_s][scope.to_s] ||= {}
          session['omniauth_step_up_auth'][provider.to_s][scope.to_s]['state'] = new_state.to_s
        end

        def conditions_fulfilled?(oidc_id_token_claims)
          ::Gitlab::Auth::Oidc::StepUpAuthentication
            .conditions_fulfilled?(oauth_extra_metadata: oidc_id_token_claims, provider: provider, scope: scope)
        end
      end
    end
  end
end
