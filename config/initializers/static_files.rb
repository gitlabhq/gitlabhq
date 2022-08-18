# frozen_string_literal: true

app = Rails.application

# Disable Sendfile for Sidekiq Web assets since Workhorse won't
# always have access to these files.
app.config.middleware.insert_before(Rack::Sendfile, Gitlab::Middleware::SidekiqWebStatic)

if app.config.public_file_server.enabled
  # The `ActionDispatch::Static` middleware intercepts requests for static files
  # by checking if they exist in the `/public` directory.
  # We're replacing it with our `Gitlab::Middleware::Static` that does the same,
  # except ignoring `/uploads`, letting those go through to the GitLab Rails app.

  app.config.middleware.swap(
    ActionDispatch::Static,
    Gitlab::Middleware::Static,
    app.paths["public"].first,
    headers: app.config.public_file_server.headers
  )

  # If webpack-dev-server is configured, proxy webpack's public directory
  # instead of looking for static assets
  if Gitlab.config.webpack.dev_server.enabled && Gitlab.dev_or_test_env?
    app.config.middleware.insert_before(
      Gitlab::Middleware::Static,
      Gitlab::Webpack::DevServerMiddleware,
      proxy_path: Gitlab.config.webpack.public_path,
      proxy_host: Gitlab.config.webpack.dev_server.host,
      proxy_port: Gitlab.config.webpack.dev_server.port,
      proxy_https: Gitlab.config.webpack.dev_server.https
    )
  end
end
