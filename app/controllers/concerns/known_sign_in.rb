# frozen_string_literal: true

module KnownSignIn
  include Gitlab::Utils::StrongMemoize
  include CookiesHelper

  KNOWN_SIGN_IN_COOKIE = :known_sign_in
  KNOWN_SIGN_IN_COOKIE_EXPIRY = 14.days

  private

  def verify_known_sign_in
    return unless Gitlab::CurrentSettings.notify_on_unknown_sign_in? && current_user

    notify_user unless known_device? || known_remote_ip?

    update_cookie
  end

  def known_remote_ip?
    known_ip_addresses.include?(request.remote_ip)
  end

  def known_device?
    cookies.encrypted[KNOWN_SIGN_IN_COOKIE] == current_user.id
  end

  def update_cookie
    set_secure_cookie(
      KNOWN_SIGN_IN_COOKIE,
      current_user.id,
      type: COOKIE_TYPE_ENCRYPTED,
      httponly: true,
      expires: KNOWN_SIGN_IN_COOKIE_EXPIRY
    )
  end

  def sessions
    ActiveSession.list(current_user).reject(&:is_impersonated)
  end
  strong_memoize_attr :sessions

  def known_ip_addresses
    [current_user.last_sign_in_ip, sessions.map(&:ip_address)].flatten
  end

  def notify_user
    request_info = Gitlab::Auth::VisitorLocation.new(request)
    current_user.notification_service.unknown_sign_in(
      current_user,
      request.remote_ip,
      current_user.current_sign_in_at,
      request_info
    )
  end
end
