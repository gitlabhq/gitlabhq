# frozen_string_literal: true

module Oauth
  class ProtectedResourceMetadataController < ApplicationController
    include ::Gitlab::EndpointAttributes

    feature_category :system_access
    skip_before_action :authenticate_user!

    def show
      expires_in 24.hours, public: true, must_revalidate: true, 'no-transform': true
      render json: resource_metadata
    end

    private

    def resource_metadata
      {
        resource: [
          Gitlab::Utils.append_path(Gitlab.config.gitlab.url, '/api/v4/mcp')
        ],
        authorization_servers: [
          Gitlab.config.gitlab.url
        ]
      }
    end
  end
end
