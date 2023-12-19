# frozen_string_literal: true

module Integrations
  module GoogleCloudPlatform
    class BaseClient
      GLGO_BASE_URL = if Gitlab.staging?
                        'https://glgo.staging.runway.gitlab.net'
                      else
                        'https://glgo.runway.gitlab.net'
                      end

      def initialize(project:, user:)
        @project = project
        @user = user
      end

      private

      def encoded_jwt(wlif:)
        jwt = ::Integrations::GoogleCloudPlatform::Jwt.new(
          project: @project,
          user: @user,
          claims: {
            audience: GLGO_BASE_URL,
            wlif: wlif
          }
        )
        jwt.encoded
      end
    end
  end
end
