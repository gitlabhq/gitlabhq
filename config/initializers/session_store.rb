# Be sure to restart your server when you modify this file.

Gitlab::Application.config.session_store(
  :redis_store, # Using the cookie_store would enable session replay attacks.
  servers: Gitlab::Application.config.cache_store[1].merge(namespace: 'session:gitlab'), # re-use the Redis config from the Rails cache store
  key: '_gitlab_session',
  secure: Gitlab.config.gitlab.https,
  httponly: true,
  expire_after: 1.week,
  path: (Rails.application.config.relative_url_root.nil?) ? '/' : Rails.application.config.relative_url_root
)
