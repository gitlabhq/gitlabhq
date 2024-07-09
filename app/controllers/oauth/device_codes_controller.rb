# frozen_string_literal: true

module Oauth
  class DeviceCodesController < Doorkeeper::DeviceAuthorizationGrant::DeviceCodesController
    def create
      # rubocop:disable Gitlab/FeatureFlagWithoutActor -- Does not execute in user context
      return :not_found unless Feature.enabled?(:oauth2_device_grant_flow)

      # rubocop:enable Gitlab/FeatureFlagWithoutActor

      super
    end
  end
end
