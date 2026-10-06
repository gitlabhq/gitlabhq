# frozen_string_literal: true

module API
  class Integrations
    module JiraForge
      # Shared auth for the native Forge app's inbound calls. Every app-context
      # call (invokeRemote) authenticates with a verified Forge Invocation Token
      # (FIT). The first-link call also carries the GitLab user as a signed
      # delegation token (X-Gitlab-Jira-User-Delegation), minted by the
      # user_delegation endpoint from the user's OAuth token; the FIT alone
      # carries no GitLab user identity.
      module Helpers
        include Gitlab::Utils::StrongMemoize

        # Installation for an app-context request, authenticated by the FIT (the
        # cloud-id header is not accepted here).
        def forge_installation
          fit = valid_forge_token
          return unless fit&.installation_id

          JiraConnectInstallation.find_or_backfill_by_forge_token(
            installation_id: fit.installation_id, cloud_id: fit.cloud_id,
            organization_id: Current.organization.id
          )
        end

        # Jira apiBaseUrl from the verified FIT. See Atlassian::Forge::SystemTokenClient.
        def forge_api_base_url
          valid_forge_token&.api_base_url
        end

        # Jira user behind an app-context call: the FIT principal, else the
        # X-Gitlab-Jira-Account-Id header.
        def forge_jira_user(installation)
          return if installation.nil?

          account_id = valid_forge_token&.principal.presence || headers['X-Gitlab-Jira-Account-Id'].presence
          return if account_id.blank?

          installation.client.user_info(account_id)
        end

        # Jira user for a first-link call, resolved directly from the FIT +
        # system token before any installation row exists. The caller has
        # already rejected a blank apiBaseUrl, system token or principal.
        def forge_native_jira_user(api_base_url, system_token, principal)
          Atlassian::Forge::SystemTokenClient.new(api_base_url, system_token).user_info(principal)
        end

        # GitLab user bound to an app-context call via the signed delegation
        # token minted by the user_delegation endpoint (the FIT bearer carries
        # no GitLab user identity). The token must have been minted for the
        # Jira account + site of this call's FIT, and the user must still be
        # active. See Integrations::JiraForge::UserDelegationToken.
        def forge_delegated_user(fit)
          jwt = headers['X-Gitlab-Jira-User-Delegation'].presence
          return if jwt.blank?

          delegation = ::Integrations::JiraForge::UserDelegationToken.decode(jwt)
          return unless delegation&.matches_fit?(fit)

          user = User.find_by_id(delegation.user_id)
          user if user && api_access_allowed?(user)
        end

        def jira_admin_error
          s_('JiraConnect|The Jira user is not a site or organization administrator. ' \
            'Check the permissions in Jira and try again.')
        end

        private

        # The verified FIT when the bearer is one (RS256 + a `kid` header); nil
        # for GitLab OAuth user tokens or an invalid token.
        def valid_forge_token
          token = bearer_token
          return if token.blank? || !forge_invocation_token?(token)

          fit = Atlassian::Forge::InvocationToken.new(token, audience: forge_app_id)
          fit if fit.valid?
        end

        # Expected FIT audience (our Forge app ARI). The admin-configurable
        # application setting is authoritative when present (set per instance for
        # a manual/self-managed Forge install); the gitlab.yml value is the
        # fallback for gitlab.com / managed configs.
        def forge_app_id
          Gitlab::CurrentSettings.jira_forge_app_id.presence || Gitlab.config.jira_connect.forge_app_id
        end
        strong_memoize_attr :valid_forge_token

        def forge_invocation_token?(token)
          _, header = JWT.decode(token, nil, false)
          header['alg'] == Atlassian::Forge::InvocationToken::ALGORITHM && header['kid'].present?
        rescue JWT::DecodeError
          false
        end

        def bearer_token
          request.headers['Authorization']&.split(' ', 2)&.last
        end
      end
    end
  end
end
