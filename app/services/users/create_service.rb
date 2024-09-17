# frozen_string_literal: true

module Users
  class CreateService < BaseService
    include NewUserNotifier

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params.dup
    end

    def execute
      user = build_class.new(current_user, params).execute
      reset_token = user.generate_reset_token if user.recently_sent_password_reset?

      after_create_hook(user, reset_token) if user.save

      user
    end

    private

    def after_create_hook(user, reset_token)
      notify_new_user(user, reset_token)
    end

    def build_class
      # overridden by inheriting classes
      Users::BuildService
    end
  end
end

Users::CreateService.prepend_mod_with('Users::CreateService')
