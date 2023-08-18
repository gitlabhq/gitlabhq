# frozen_string_literal: true

module KasCookie
  extend ActiveSupport::Concern

  included do
    content_security_policy_with_context do |p|
      next unless ::Gitlab::Kas::UserAccess.enabled?
      next unless Settings.gitlab.content_security_policy['enabled']

      next if URI(kas_url).host == ::Gitlab.config.gitlab.host # already allowed, no need for exception

      p.connect_src(*Array.wrap(p.directives['connect-src']), kas_ws_url.sub(%r{/?$}, '/'))
      p.connect_src(*Array.wrap(p.directives['connect-src']), kas_url.sub(%r{/?$}, '/'))
    end
  end

  def set_kas_cookie
    return unless ::Gitlab::Kas::UserAccess.enabled?

    public_session_id = Gitlab::Session.current&.id&.public_id
    return unless public_session_id

    cookie_data = ::Gitlab::Kas::UserAccess.cookie_data(public_session_id)

    cookies[::Gitlab::Kas::COOKIE_KEY] = cookie_data
  end

  private

  def kas_url
    ::Gitlab::Kas.tunnel_url
  end

  def kas_ws_url
    ::Gitlab::Kas.tunnel_ws_url
  end
end
