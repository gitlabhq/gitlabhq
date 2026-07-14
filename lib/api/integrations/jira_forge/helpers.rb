# frozen_string_literal: true

module API
  class Integrations
    module JiraForge
      # Shared auth for the native Forge app's inbound calls. App-context calls
      # (invokeRemote) authenticate with a verified Forge Invocation Token (FIT);
      # the OAuth subscription-create call carries a GitLab user token and finds
      # the installation by the X-Gitlab-Jira-Cloud-Id header (gated by user +
      # Jira admin, so the header alone grants nothing).
      module Helpers
        include Gitlab::Utils::StrongMemoize

        # Installation for an app-context request, authenticated by the FIT (the
        # cloud-id header is not accepted here).
        def forge_installation
          return unless valid_forge_token&.cloud_id

          JiraConnectInstallation.find_by_cloud_id_and_organization_id(
            valid_forge_token.cloud_id, Current.organization.id
          )
        end

        # Installation for the OAuth subscription-create call (no FIT), by cloud-id
        # header; gated by GitLab user + Jira admin.
        def forge_oauth_installation
          cloud_id = headers['X-Gitlab-Jira-Cloud-Id'].presence
          return if cloud_id.blank?

          JiraConnectInstallation.find_by_cloud_id_and_organization_id(cloud_id, Current.organization.id)
        end

        # Jira apiBaseUrl from the verified FIT. See Atlassian::Forge::SystemTokenClient.
        def forge_api_base_url
          valid_forge_token&.api_base_url
        end

        # Jira user behind the call: the FIT principal, else the
        # X-Gitlab-Jira-Account-Id header.
        def forge_jira_user(installation)
          return if installation.nil?

          account_id = valid_forge_token&.principal.presence || headers['X-Gitlab-Jira-Account-Id'].presence
          return if account_id.blank?

          installation.client.user_info(account_id)
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
