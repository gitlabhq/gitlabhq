begin
  app = Rails.application

  app.config.middleware.swap(
    ActionDispatch::Static, 
    Gitlab::Middleware::Static, 
    app.paths["public"].first, 
    app.config.static_cache_control
  )
rescue
  # If ActionDispatch::Static wasn't loaded onto the stack (like in production), 
  # an exception is raised.
end