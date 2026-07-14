# frozen_string_literal: true

Rails.application.configure do |config|
  config.middleware.insert_after Labkit::Middleware::Rack, Gitlab::Middleware::RequestCost
end
