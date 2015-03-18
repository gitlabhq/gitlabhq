# Slowpoke extends Rack::Timeout to gracefully kill Unicorn workers so they can clean up state.
Slowpoke.timeout = 60

# The `Rack::Timeout` middleware kills requests after 60 seconds (as set above).
# We're replacing it with our `Gitlab::Middleware::Timeout` that does the same,
# except ignoring Git-over-HTTP requests, letting those take as long as they need.

Rails.application.config.middleware.swap(Rack::Timeout, Gitlab::Middleware::Timeout)
