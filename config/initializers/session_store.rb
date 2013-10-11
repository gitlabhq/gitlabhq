# Be sure to restart your server when you modify this file.

Gitlab::Application.config.session_store(
  :redis_store, # Using the cookie_store would enable session replay attacks.
  key: '_gitlab_session',
  secure: Gitlab::Application.config.force_ssl,
  httponly: true,
  path: (Rails.application.config.relative_url_root.nil?) ? '/' : Rails.application.config.relative_url_root
)
