# frozen_string_literal: true

module Users
  class BannedUserBaseService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      return permission_error unless allowed?

      if update_user(user)
        log_event(user)
        success
      else
        messages = user.errors.full_messages
        error(messages.uniq.join('. '))
      end
    end

    private

    attr_reader :current_user

    def allowed?
      can?(current_user, :admin_all_resources)
    end

    def permission_error
      error(_("You are not allowed to %{action} a user" % { action: action.to_s }), :forbidden)
    end

    def log_event(user)
      Gitlab::AppLogger.info(message: "User #{action}", user: "#{user.username}", email: "#{user.email}", "#{action}_by": "#{current_user.username}", ip_address: "#{current_user.current_sign_in_ip}")
    end
  end
end
