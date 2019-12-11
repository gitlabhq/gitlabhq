# frozen_string_literal: true

# == SessionlessAuthentication
#
# Controller concern to handle PAT, RSS, and static objects token authentication methods
#
module SessionlessAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :enable_admin_mode!, if: :sessionless_user?
  end

  # This filter handles personal access tokens, atom requests with rss tokens, and static object tokens
  def authenticate_sessionless_user!(request_format)
    user = Gitlab::Auth::RequestAuthenticator.new(request).find_sessionless_user(request_format)

    sessionless_sign_in(user) if user
  end

  def sessionless_user?
    current_user && !session.key?('warden.user.user.key')
  end

  def sessionless_sign_in(user)
    if user && can?(user, :log_in)
      # Notice we are passing store false, so the user is not
      # actually stored in the session and a token is needed
      # for every request. If you want the token to work as a
      # sign in token, you can simply remove store: false.
      sign_in(user, store: false, message: :sessionless_sign_in)
    end
  end

  def enable_admin_mode!
    return unless Feature.enabled?(:user_mode_in_session)

    current_user_mode.enable_sessionless_admin_mode!
  end
end
