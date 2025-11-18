# frozen_string_literal: true

module Gitlab
  module Auth
    module Oidc
      # Handles step-up authentication configuration and validation for OAuth providers
      #
      # This module manages the configuration and validation of step-up authentication
      # requirements for OAuth providers, particularly focusing on admin mode access.
      module StepUpAuthentication
        SESSION_STORE_KEY = 'omniauth_step_up_auth'

        SCOPE_ADMIN_MODE = :admin_mode
        SCOPE_NAMESPACE = :namespace

        ALLOWED_SCOPES = [
          SCOPE_ADMIN_MODE,
          SCOPE_NAMESPACE
        ].freeze

        class << self
          # Checks if step-up authentication is enabled for the step-up auth scope 'admin_mode'
          #
          # @return [Boolean] true if any OAuth provider requires step-up auth for admin mode
          def enabled_by_config?(scope: SCOPE_ADMIN_MODE)
            oauth_providers.any? do |provider|
              enabled_for_provider?(provider_name: provider, scope: scope)
            end
          end

          # Checks if step-up authentication configuration exists for a provider name
          #
          # @param oauth_provider_name [String] the name of the OAuth provider
          # @param scope [Symbol] the scope to check configuration for (default: :admin_mode)
          # @return [Boolean] true if configuration exists
          def enabled_for_provider?(provider_name:, scope: SCOPE_ADMIN_MODE)
            has_required_claims?(provider_name, scope) ||
              has_included_claims?(provider_name, scope)
          end

          def enabled_providers(scope: SCOPE_ADMIN_MODE)
            oauth_providers.select do |provider|
              enabled_for_provider?(provider_name: provider, scope: scope)
            end
          end

          # Verifies if step-up authentication has succeeded for any provider
          # with the step-up auth scope 'admin_mode'
          #
          # @param session [Hash] the session hash containing authentication state
          # @return [Boolean] true if step-up authentication is authenticated and not expired
          def succeeded?(session, scope: SCOPE_ADMIN_MODE)
            step_up_auth_flows(session)
              .select do |step_up_auth_flow|
                step_up_auth_flow.scope.to_s == scope.to_s
              end
              .select(&:enabled_by_config?)
              .any?(&:succeeded?)
          end

          # Validates if all step-up authentication conditions are met
          #
          # @param oauth [OAuth2::AccessToken] the OAuth object to validate
          # @param scope [Symbol] the scope to validate conditions for (default: :admin_mode)
          # @return [Boolean] true if all conditions are fulfilled
          def conditions_fulfilled?(oauth_extra_metadata:, provider:, scope: SCOPE_ADMIN_MODE)
            conditions = []

            if has_required_claims?(provider, scope)
              conditions << required_conditions_fulfilled?(oauth_extra_metadata: oauth_extra_metadata,
                provider: provider, scope: scope)
            end

            if has_included_claims?(provider, scope)
              conditions << included_conditions_fulfilled?(oauth_extra_metadata: oauth_extra_metadata,
                provider: provider, scope: scope)
            end

            conditions.present? && conditions.all?
          end

          def build_flow(provider:, session:, scope: SCOPE_ADMIN_MODE)
            Gitlab::Auth::Oidc::StepUpAuthenticationFlow.new(provider: provider, scope: scope, session: session)
          end

          # Slices the relevant ID token claims from the provided OAuth raw information.
          #
          # @param oauth_raw_info [Hash] The raw information received from the OAuth provider.
          # @param provider [String] The name of the OAuth provider.
          # @param scope [String] The scope of the authentication request, default is SCOPE_ADMIN_MODE.
          # @return [Hash] A hash containing only the relevant ID token claims.
          def slice_relevant_id_token_claims(oauth_raw_info:, provider:, scope: SCOPE_ADMIN_MODE)
            relevant_id_token_claims = [
              *get_id_token_claims_required_conditions(provider, scope)&.keys,
              *get_id_token_claims_included_conditions(provider, scope)&.keys
            ]
            oauth_raw_info.slice(*relevant_id_token_claims, 'exp')
          end

          def omniauth_step_up_auth_session_data(session)
            Gitlab::NamespacedSessionStore.new(SESSION_STORE_KEY, session)
          end

          def disable_step_up_authentication!(session:, scope: SCOPE_ADMIN_MODE)
            omniauth_step_up_auth_session_data(session)
                      &.to_h
                      &.each_value do |step_up_auth_object|
                        step_up_auth_object.delete(scope.to_s)
                      end
          end

          # Returns step-up authentication flows that have failed
          #
          # @param session [Hash] the session hash containing authentication state
          # @param scope [Symbol] the scope to check (default: :admin_mode)
          # @return [Array<StepUpAuthenticationFlow>] list of failed authentication flows
          def failed_step_up_auth_flows(session, scope: SCOPE_ADMIN_MODE)
            (step_up_auth_flows(session) || []).select do |flow|
              flow.enabled_by_config? &&
                flow.failed? &&
                flow.scope.to_s == scope.to_s
            end
          end

          def step_up_session_expired?(session, scope: SCOPE_ADMIN_MODE)
            (step_up_auth_flows(session) || []).any? do |flow|
              flow.enabled_by_config? &&
                flow.expired? &&
                flow.scope.to_s == scope.to_s
            end
          end

          private

          def oauth_providers
            Gitlab::Auth::OAuth::Provider.providers || []
          end

          def has_required_claims?(provider_name, scope)
            get_id_token_claims_required_conditions(provider_name, scope).present?
          end

          def has_included_claims?(provider_name, scope)
            get_id_token_claims_included_conditions(provider_name, scope).present?
          end

          def get_id_token_claims_required_conditions(provider_name, scope)
            dig_provider_config(provider_name, scope, 'required')
          end

          def get_id_token_claims_included_conditions(provider_name, scope)
            dig_provider_config(provider_name, scope, 'included')
          end

          def dig_provider_config(provider_name, scope, claim_type)
            Gitlab::Auth::OAuth::Provider
              .config_for(provider_name.to_s)
              &.dig('step_up_auth', scope.to_s, 'id_token', claim_type)
          end

          def included_conditions_fulfilled?(oauth_extra_metadata:, provider:, scope:)
            conditions = get_id_token_claims_included_conditions(provider, scope)

            raw_info = (oauth_extra_metadata.presence || {}).with_indifferent_access
            conditions.to_h.all? do |claim_key, expected_included_value|
              raw_info_value = raw_info[claim_key]
              next false if raw_info_value.blank?

              Array.wrap(expected_included_value).any? do |v|
                case raw_info_value
                when String, Hash, Array
                  raw_info_value.include?(v)
                else
                  raw_info_value == v
                end
              end
            end
          end

          def required_conditions_fulfilled?(oauth_extra_metadata:, provider:, scope:)
            conditions = get_id_token_claims_required_conditions(provider, scope)

            raw_info = oauth_extra_metadata.presence || {}
            subset?(raw_info, conditions)
          end

          def subset?(hash, subset_hash)
            hash.with_indifferent_access >= subset_hash.with_indifferent_access
          end

          def step_up_auth_flows(session)
            omniauth_step_up_auth_session_data(session)
              &.to_h
              &.flat_map do |provider, step_up_auth_object|
                step_up_auth_object.map do |step_up_auth_scope, _|
                  build_flow(provider: provider, session: session, scope: step_up_auth_scope)
                rescue ArgumentError => e
                  Gitlab::AppLogger.error("Error building step-up authentication flow: #{e.message}")
                  nil
                end
              end
              &.compact
          end
        end
      end
    end
  end
end
