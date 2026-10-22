# frozen_string_literal: true

module API
  module Helpers
    module Mcp
      # Adds an RFC 9728 Section 5.1 WWW-Authenticate challenge to 401 responses, and to the
      # API guard's insufficient_scope 403, so MCP clients can discover the OAuth
      # protected-resource metadata URL.
      module AuthChallenge
        extend ::Gitlab::Utils::Override

        WWW_AUTHENTICATE_HEADER = 'WWW-Authenticate'

        override :unauthorized!
        def unauthorized!(reason = nil)
          header(WWW_AUTHENTICATE_HEADER, mcp_www_authenticate_challenge)
          super
        end

        private

        override :bearer_challenge
        def bearer_challenge(error:, error_description:, scope: nil)
          mcp_www_authenticate_challenge(error: error, error_description: error_description, scope: scope)
        end

        # An empty scope is left out, as in the 403's body.
        def mcp_www_authenticate_challenge(error: nil, error_description: nil, scope: nil)
          # RFC 9728 Section 3.1 path-insertion: insert the well-known segment between
          # host and resource path, e.g. "<url>/.well-known/oauth-protected-resource/api/v4/mcp".
          # This matches the metadata route registered in config/routes.rb.
          metadata_url = Gitlab::Utils.append_path(
            Gitlab.config.gitlab.url,
            "/.well-known/oauth-protected-resource#{resource_path}"
          )
          attributes = {
            realm: 'GitLab',
            error: error,
            error_description: error_description,
            scope: scope || required_scope,
            resource_metadata: metadata_url
          }.compact_blank
          "Bearer #{attributes.map { |name, value| %(#{name}="#{value}") }.join(', ')}"
        end

        def required_scope
          ::Gitlab::Auth::MCP_RESOURCE_SCOPES.fetch(resource_path, ::Gitlab::Auth::MCP_SCOPE)
        end

        # `request.path` includes the relative URL root on a subpath install
        # (e.g. "/gitlab/api/v4/mcp"). Strip it, because Gitlab.config.gitlab.url
        # already contains the relative root and would otherwise be duplicated.
        def resource_path
          relative_root = File.join('', Gitlab.config.gitlab.relative_url_root).chomp('/')
          request.path.delete_prefix(relative_root)
        end
      end
    end
  end
end
