# frozen_string_literal: true

# == SessionlessAuthentication
#
# Controller concern to handle PAT, RSS, and static objects token authentication methods
#
module SessionlessAuthentication
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

  def sessionless_bypass_admin_mode!(&block)
    return yield unless Feature.enabled?(:user_mode_in_session)

    Gitlab::Auth::CurrentUserMode.bypass_session!(current_user.id, &block)
  end
end
