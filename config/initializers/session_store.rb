# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'

# allow it to fail: it may do so when create_from_defaults is executed before migrations are actually done
begin
  Settings.gitlab['session_expire_delay'] = Gitlab::CurrentSettings.current_application_settings.session_expire_delay || 10080
rescue StandardError
  Settings.gitlab['session_expire_delay'] ||= 10080
end

cookie_key = if Rails.env.development?
               "_gitlab_session_#{Digest::SHA256.hexdigest(Rails.root.to_s)}"
             elsif ::Gitlab.ee? && ::Gitlab::Geo.connected? && ::Gitlab::Geo.secondary?
               "_gitlab_session_geo_#{Digest::SHA256.hexdigest(GeoNode.current_node_name)}"
             else
               "_gitlab_session"
             end

store = Gitlab::Redis::Sessions.store(namespace: Gitlab::Redis::Sessions::SESSION_NAMESPACE)

Gitlab::Application.config.session_store(
  :redis_store, # Using the cookie_store would enable session replay attacks.
  redis_store: store,
  key: cookie_key,
  secure: Gitlab.config.gitlab.https,
  httponly: true,
  expires_in: Settings.gitlab['session_expire_delay'] * 60,
  path: Rails.application.config.relative_url_root.presence || '/'
)
