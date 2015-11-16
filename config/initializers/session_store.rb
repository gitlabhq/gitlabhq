# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'
include Gitlab::CurrentSettings

# allow it to fail: it may to do so when create_from_defaults is executed before migrations are actually done
begin
  Settings.gitlab['session_expire_delay'] = current_application_settings.session_expire_delay
rescue
end

unless Rails.env.test?
  Gitlab::Application.config.session_store(
    :redis_store, # Using the cookie_store would enable session replay attacks.
    servers: Gitlab::Application.config.cache_store[1].merge(namespace: 'session:gitlab'), # re-use the Redis config from the Rails cache store
    key: '_gitlab_session',
    secure: Gitlab.config.gitlab.https,
    httponly: true,
    expire_after: Settings.gitlab['session_expire_delay'] * 60,
    path: (Gitlab::Application.config.relative_url_root.nil?) ? '/' : Gitlab::Application.config.relative_url_root
  )
end
