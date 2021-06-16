# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

def master_process?
  Prometheus::PidProvider.worker_id == 'puma_master'
end

warmup do |app|
  client = Rack::MockRequest.new(app)
  client.get('/')
end

map ENV['RAILS_RELATIVE_URL_ROOT'] || "/" do
  use Gitlab::Middleware::ReleaseEnv
  run Gitlab::Application
end
