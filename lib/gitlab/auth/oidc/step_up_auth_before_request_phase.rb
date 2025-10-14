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
            requested_scope = request_param_step_up_auth_scope_from(env).to_sym
            current_user = current_user_from(env)

            return if current_user.blank?
            return if requested_scope.blank?

            return if requested_scope_admin_mode?(requested_scope) &&
              Feature.disabled?(:omniauth_step_up_auth_for_admin_mode, current_user)

            return if requested_scope_namespace?(requested_scope) &&
              Feature.disabled?(:omniauth_step_up_auth_for_namespace, current_user)

            session = session_from(env)
            provider = current_provider_from(env)

            step_up_auth_flow =
              ::Gitlab::Auth::Oidc::StepUpAuthentication.build_flow(
                session: session,
                provider: provider,
                scope: requested_scope
              )

            # TODO: Integrate the state uuid in the step-up auth session.
            # Why? At the moment, there is a small security vulnerability
            # where simultaneous authentication requests could lead to privilege escalation, https://gitlab.com/gitlab-org/gitlab/-/issues/555349.
            return unless step_up_auth_flow.enabled_by_config?

            # This method will set the state to 'requested' in the session
            step_up_auth_flow.request!
          end

          private

          def requested_scope_admin_mode?(scope)
            scope == ::Gitlab::Auth::Oidc::StepUpAuthentication::SCOPE_ADMIN_MODE
          end

          def requested_scope_namespace?(scope)
            scope == ::Gitlab::Auth::Oidc::StepUpAuthentication::SCOPE_NAMESPACE
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
