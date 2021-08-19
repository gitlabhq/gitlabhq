# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

def master_process?
  Prometheus::PidProvider.worker_id == 'puma_master'
end

warmup do |app|
  # The following is necessary to ensure stale Prometheus metrics don't accumulate over time.
  # It needs to be done as early as here to ensure metrics files aren't deleted.
  # After we hit our app in `warmup`, first metrics and corresponding files already being created,
  # for example in `lib/gitlab/metrics/requests_rack_middleware.rb`.
  Prometheus::CleanupMultiprocDirService.new.execute if master_process?

  client = Rack::MockRequest.new(app)
  client.get('/')
end

map ENV['RAILS_RELATIVE_URL_ROOT'].presence || "/" do
  use Gitlab::Middleware::ReleaseEnv
  run Gitlab::Application
end
