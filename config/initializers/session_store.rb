# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'

# allow it to fail: it may do so when create_from_defaults is executed before migrations are actually done
begin
  Settings.gitlab['session_expire_delay'] = Gitlab::CurrentSettings.current_application_settings.session_expire_delay || 10080
rescue
  Settings.gitlab['session_expire_delay'] ||= 10080
end

cookie_key = if Rails.env.development?
               "_gitlab_session_#{Digest::SHA256.hexdigest(Rails.root.to_s)}"
             else
               "_gitlab_session"
             end

sessions_config = Gitlab::Redis::SharedState.params
sessions_config[:namespace] = Gitlab::Redis::SharedState::SESSION_NAMESPACE

Gitlab::Application.config.session_store(
  :redis_store, # Using the cookie_store would enable session replay attacks.
  servers: sessions_config,
  key: cookie_key,
  secure: Gitlab.config.gitlab.https,
  httponly: true,
  expires_in: Settings.gitlab['session_expire_delay'] * 60,
  path: Rails.application.config.relative_url_root.nil? ? '/' : Gitlab::Application.config.relative_url_root
)
