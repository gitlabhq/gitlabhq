# frozen_string_literal: true

module Keys
  class CreateService < ::Keys::BaseService
    include Gitlab::InternalEventsTracking

    attr_accessor :current_user

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
      @ip_address = @params.delete(:ip_address)
      @creation_source = @params.delete(:creation_source) || 'unknown'
      @user = params.delete(:user) || current_user
      @params[:organization] ||= user.organization
    end

    def execute
      key = user.keys.create(params)
      if key.persisted?
        notification_service.new_key(key)
        track_event(key)
      end

      key
    end

    private

    def track_event(key)
      track_internal_event(
        'create_ssh_key',
        user: user,
        additional_properties: {
          creation_source: @creation_source,
          usage_type: key.usage_type
        }
      )
    end
  end
end

Keys::CreateService.prepend_mod_with('Keys::CreateService')
