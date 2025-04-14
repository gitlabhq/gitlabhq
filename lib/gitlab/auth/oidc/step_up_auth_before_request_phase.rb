# frozen_string_literal: true

module Gitlab
  module Auth
    module Oidc
      # Handles the step-up authentication request phase for OAuth flow
      #
      # This module manages the initial phase of step-up authentication,
      # setting up the session state for admin mode authentication.
      module StepUpAuthBeforeRequestPhase
        class << self
          def call(env)
            return if current_user_from(env).blank?
            return if Feature.disabled?(:omniauth_step_up_auth_for_admin_mode, current_user_from(env))

            # If the step-up authentication scope is not included in the request params,
            # then step-up authentication is likely not requested and we do not need to proceed.
            return unless step_up_auth_requested_for_admin_mode?(env)

            session = session_from(env)
            provider = current_provider_from(env)
            step_up_auth_flow =
              ::Gitlab::Auth::Oidc::StepUpAuthentication.build_flow(session: session, provider: provider)

            return unless step_up_auth_flow.enabled_by_config?

            # This method will set the state to 'requested' in the session
            step_up_auth_flow.request!
          end

          private

          def step_up_auth_requested_for_admin_mode?(env)
            request_param_step_up_auth_scope_from(env) ==
              ::Gitlab::Auth::Oidc::StepUpAuthentication::STEP_UP_AUTH_SCOPE_ADMIN_MODE.to_s
          end

          def current_user_from(env)
            env['warden']&.user
          end

          def current_provider_from(env)
            env['omniauth.strategy']&.name
          end

          def request_param_step_up_auth_scope_from(env)
            env.dig('rack.request.query_hash', 'step_up_auth_scope').to_s
          end

          def session_from(env)
            env['rack.session']
          end
        end
      end
    end
  end
end
