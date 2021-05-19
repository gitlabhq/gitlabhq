# frozen_string_literal: true

module Users
  class BanService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      if user.ban
        log_event(user)
        success
      else
        messages = user.errors.full_messages
        error(messages.uniq.join('. '))
      end
    end

    private

    def log_event(user)
      Gitlab::AppLogger.info(message: "User banned", user: "#{user.username}", email: "#{user.email}", banned_by: "#{current_user.username}", ip_address: "#{current_user.current_sign_in_ip}")
    end
  end
end
