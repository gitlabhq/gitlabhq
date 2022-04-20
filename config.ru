# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('config/environment', __dir__)

warmup do |app|
  client = Rack::MockRequest.new(app)
  client.get('/')
end

map ENV['RAILS_RELATIVE_URL_ROOT'].presence || "/" do
  use Gitlab::Middleware::ReleaseEnv
  run Gitlab::Application
end
