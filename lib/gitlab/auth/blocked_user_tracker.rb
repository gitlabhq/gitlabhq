# frozen_string_literal: true
module Gitlab
  module Auth
    class BlockedUserTracker
      def initialize(user, auth)
        @user = user
        @auth = auth
      end

      def log_activity!
        return unless @user.blocked?

        Gitlab::AppLogger.info <<~INFO
          "Failed login for blocked user: user=#{@user.username} ip=#{@auth.request.ip}")
        INFO

        SystemHooksService.new.execute_hooks_for(@user, :failed_login)
      rescue TypeError
      end
    end
  end
end
