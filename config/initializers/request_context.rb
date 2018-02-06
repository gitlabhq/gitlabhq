Rails.application.configure do |config|
  config.middleware.insert_after RequestStore::Middleware, Gitlab::RequestContext
end
