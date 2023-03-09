# frozen_string_literal: true

module KasCookie
  extend ActiveSupport::Concern

  def set_kas_cookie
    return unless ::Gitlab::Kas::UserAccess.enabled?

    public_session_id = Gitlab::Session.current&.id&.public_id
    return unless public_session_id

    cookie_data = ::Gitlab::Kas::UserAccess.cookie_data(public_session_id)

    cookies[::Gitlab::Kas::COOKIE_KEY] = cookie_data
  end
end
