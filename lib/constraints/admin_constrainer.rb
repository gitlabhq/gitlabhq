# frozen_string_literal: true

module Constraints
  class AdminConstrainer
    def matches?(request)
      if Feature.enabled?(:user_mode_in_session)
        admin_mode_enabled?(request)
      else
        user_is_admin?(request)
      end
    end

    private

    def user_is_admin?(request)
      request.env['warden'].authenticate? && request.env['warden'].user.admin?
    end

    def admin_mode_enabled?(request)
      Gitlab::Session.with_session(request.session) do
        request.env['warden'].authenticate? && Gitlab::Auth::CurrentUserMode.new(request.env['warden'].user).admin_mode?
      end
    end
  end
end
