# Be sure to restart your server when you modify this file.

session_store = if Rails.env.prod? 
                  # Using the cookie_store would enable session replay attacks.
                  :redis_store
                else
                  :cache_store 
                end

store_options = if Rails.env.prod?
                  {
                    servers: Gitlab::Application.config.cache_store.last, # re-use the Redis config from the Rails cache store
                    key: '_gitlab_session',
                    secure: Gitlab::Application.config.force_ssl,
                    httponly: true,
                    path: (Rails.application.config.relative_url_root.nil?) ? '/' : Rails.application.config.relative_url_root
                  }
                end

Gitlab::Application.config.session_store(session_store, store_options)
