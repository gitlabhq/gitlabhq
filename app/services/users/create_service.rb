# frozen_string_literal: true

module Users
  class CreateService < BaseService
    include NewUserNotifier

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params.dup
    end

    def execute
      reset_token = user.generate_reset_token if user.recently_sent_password_reset?

      create_user(user, reset_token)
    end

    private

    def user
      @user ||= build_class.new(current_user, params).execute
    end

    def after_create_hook(user, reset_token)
      notify_new_user(user, reset_token)
    end

    def build_class
      # overridden by inheriting classes
      Users::BuildService
    end

    def create_user(user, reset_token)
      return error(user.errors.full_messages.to_sentence, { user: user }) if user.errors.any?

      if user.save
        after_create_hook(user, reset_token)
        success({ user: user })
      else
        error(user.errors.full_messages.to_sentence, { user: user })
      end
    end

    def error(message, payload)
      ServiceResponse.error(message: message, payload: payload)
    end

    def success(payload)
      ServiceResponse.success(payload: payload)
    end
  end
end

Users::CreateService.prepend_mod_with('Users::CreateService')
