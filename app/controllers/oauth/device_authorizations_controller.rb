# frozen_string_literal: true

module Oauth
  class DeviceAuthorizationsController < Doorkeeper::DeviceAuthorizationGrant::DeviceAuthorizationsController
    include RequestPayloadLogger

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
      @application = device_grant&.application
      respond_to do |format|
        format.html do
          render "doorkeeper/device_authorization_grant/authorize"
        end
        format.json { head :no_content }
      end
    end

    private

    # In Rails 8 alias_method at class-body level fails when the aliased method
    # is not yet in the ancestor chain at load time. Define explicitly instead.
    def auth_user
      current_user
    end
  end
end
