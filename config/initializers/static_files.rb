app = Rails.application

if app.config.serve_static_files
  # The `ActionDispatch::Static` middleware intercepts requests for static files 
  # by checking if they exist in the `/public` directory. 
  # We're replacing it with our `Gitlab::Middleware::Static` that does the same,
  # except ignoring `/uploads`, letting those go through to the GitLab Rails app.

  app.config.middleware.swap(
    ActionDispatch::Static, 
    Gitlab::Middleware::Static, 
    app.paths["public"].first, 
    app.config.static_cache_control
  )

  # If webpack-dev-server is configured, proxy webpack's public directory
  # instead of looking for static assets
  if Gitlab.config.webpack.dev_server.enabled
    app.config.webpack.dev_server.merge!(
      enabled: true,
      host: Gitlab.config.gitlab.host,
      port: Gitlab.config.gitlab.port,
      https: Gitlab.config.gitlab.https,
      manifest_host: Gitlab.config.webpack.dev_server.host,
      manifest_port: Gitlab.config.webpack.dev_server.port,
    )

    app.config.middleware.insert_before(
      Gitlab::Middleware::Static,
      Gitlab::Middleware::WebpackProxy,
      proxy_path: app.config.webpack.public_path,
      proxy_host: Gitlab.config.webpack.dev_server.host,
      proxy_port: Gitlab.config.webpack.dev_server.port,
    )
  end
end
