# frozen_string_literal: true

module Keys
  class CreateService < ::Keys::BaseService
    attr_accessor :current_user

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
      @ip_address = @params.delete(:ip_address)
      @user = params.delete(:user) || current_user
    end

    def execute
      key = user.keys.create(params)
      notification_service.new_key(key) if key.persisted?
      key
    end
  end
end

Keys::CreateService.prepend_mod_with('Keys::CreateService')
