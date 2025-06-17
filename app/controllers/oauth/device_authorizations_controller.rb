# frozen_string_literal: true

module Oauth
  class DeviceAuthorizationsController < Doorkeeper::DeviceAuthorizationGrant::DeviceAuthorizationsController
    layout 'minimal'

    def index
      respond_to do |format|
        format.html do
          render "doorkeeper/device_authorization_grant/index"
        end
        format.json { head :no_content }
      end
    end

    def confirm
      # rubocop:disable CodeReuse/ActiveRecord -- We are using .find_by here because the models are part of the Doorkeeper gem.
      device_grant = device_grant_model.find_by(user_code: user_code)
      # rubocop:enable CodeReuse/ActiveRecord
      @scopes = device_grant&.scopes || ''
      respond_to do |format|
        format.html do
          render "doorkeeper/device_authorization_grant/authorize"
        end
        format.json { head :no_content }
      end
    end
  end
end
