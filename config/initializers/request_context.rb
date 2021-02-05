# frozen_string_literal: true

Rails.application.configure do |config|
  config.middleware.insert_after RequestStore::Middleware, Gitlab::Middleware::RequestContext
end
