# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- reuse the existing Atlassian module namespace
module Atlassian
  module Forge
    # Sends dev-info to Jira directly with a Forge app system OAuth token
    # (x-forge-oauth-system) instead of the Connect shared_secret. Subclasses the
    # Connect Client to reuse payload building; only the auth header changes.
    # See https://developer.atlassian.com/platform/forge/remote/calling-product-apis/
    class SystemTokenClient < ::Atlassian::JiraConnect::Client
      # api_base_url is the FIT app.apiBaseUrl (carries a /ex/jira/<cloudId> path
      # prefix the parent's build_uri preserves); system_token is the appSystemToken.
      def initialize(api_base_url, system_token)
        @system_token = system_token

        super(api_base_url, nil)
      end

      private

      # Bearer auth with the Forge system token; no Connect JWT signing.
      def headers(_uri, _http_method = 'POST')
        {
          'Authorization' => "Bearer #{@system_token}",
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
