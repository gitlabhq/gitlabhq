# frozen_string_literal: true

module Oauth
  class ProtectedResourceMetadataController < ApplicationController
    include ::Gitlab::EndpointAttributes

    feature_category :system_access
    skip_before_action :authenticate_user!

    MCP_RESOURCE_PATHS = {
      '/api/v4/mcp' => Gitlab::Auth::MCP_SCOPE,
      '/api/v4/orbit/mcp' => Gitlab::Auth::MCP_ORBIT_SCOPE
    }.freeze

    def show
      expires_in 24.hours, public: true, must_revalidate: true, 'no-transform': true
      render json: resource_metadata
    end

    private

    def resource_metadata
      MCP_RESOURCE_PATHS.each do |path, scope|
        return resource_metadata_for(path, scope) if request.path.end_with?(path)
      end

      {
        resource: MCP_RESOURCE_PATHS.keys.map { |path| Gitlab::Utils.append_path(Gitlab.config.gitlab.url, path) },
        authorization_servers: [Gitlab.config.gitlab.url],
        scopes_supported: MCP_RESOURCE_PATHS.values.map(&:to_s)
      }
    end

    def resource_metadata_for(path, scope)
      {
        resource: [Gitlab::Utils.append_path(Gitlab.config.gitlab.url, path)],
        authorization_servers: [Gitlab.config.gitlab.url],
        scopes_supported: [scope.to_s]
      }
    end
  end
end
