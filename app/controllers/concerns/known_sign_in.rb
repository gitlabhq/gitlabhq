# frozen_string_literal: true

module KnownSignIn
  include Gitlab::Utils::StrongMemoize

  private

  def verify_known_sign_in
    return unless current_user

    notify_user unless known_remote_ip?
  end

  def known_remote_ip?
    known_ip_addresses.include?(request.remote_ip)
  end

  def sessions
    strong_memoize(:session) do
      ActiveSession.list(current_user).reject(&:is_impersonated)
    end
  end

  def known_ip_addresses
    [current_user.last_sign_in_ip, sessions.map(&:ip_address)].flatten
  end

  def notify_user
    current_user.notification_service.unknown_sign_in(current_user, request.remote_ip, current_user.current_sign_in_at)
  end
end
