app = Rails.application

if (Gitlab.rails5? && app.config.public_file_server.enabled) || app.config.serve_static_files
  # The `ActionDispatch::Static` middleware intercepts requests for static files
  # by checking if they exist in the `/public` directory.
  # We're replacing it with our `Gitlab::Middleware::Static` that does the same,
  # except ignoring `/uploads`, letting those go through to the GitLab Rails app.

  if Gitlab.rails5?
    app.config.middleware.swap(
      ActionDispatch::Static,
      Gitlab::Middleware::Static,
      app.paths["public"].first,
      headers: app.config.public_file_server.headers
    )
  else
    app.config.middleware.swap(
      ActionDispatch::Static,
      Gitlab::Middleware::Static,
      app.paths["public"].first,
      app.config.static_cache_control
    )
  end

  # If webpack-dev-server is configured, proxy webpack's public directory
  # instead of looking for static assets
  dev_server = Gitlab.config.webpack.dev_server

  if dev_server.enabled
    settings = {
      enabled: true,
      host: dev_server.host,
      port: dev_server.port,
      manifest_host: dev_server.host,
      manifest_port: dev_server.port
    }

    if Rails.env.development?
      settings.merge!(
        host: Gitlab.config.gitlab.host,
        port: Gitlab.config.gitlab.port,
        https: false
      )
      app.config.middleware.insert_before(
        Gitlab::Middleware::Static,
        Gitlab::Webpack::DevServerMiddleware,
        proxy_path: app.config.webpack.public_path,
        proxy_host: dev_server.host,
        proxy_port: dev_server.port
      )
    end

    app.config.webpack.dev_server.merge!(settings)
  end
end
