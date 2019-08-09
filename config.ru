# This file is used by Rack-based servers to start the application.

if defined?(Unicorn)
  require 'unicorn'

  if ENV['RAILS_ENV'] == 'production' || ENV['RAILS_ENV'] == 'staging'
    # Unicorn self-process killer
    require 'unicorn/worker_killer'

    min = (ENV['GITLAB_UNICORN_MEMORY_MIN'] || 400 * 1 << 20).to_i
    max = (ENV['GITLAB_UNICORN_MEMORY_MAX'] || 650 * 1 << 20).to_i

    # Max memory size (RSS) per worker
    use Unicorn::WorkerKiller::Oom, min, max
  end
end

require ::File.expand_path('../config/environment', __FILE__)


# The following is necessary to ensure stale Prometheus metrics don't accumulate over time.
# It needs to be done as early as here to ensure metrics files aren't deleted.
# After we hit our app in `warmup`, first metrics and corresponding files already being created,
# for example in `lib/gitlab/metrics/requests_rack_middleware.rb`.
def cleanup_prometheus_multiproc_dir
  if dir = ::Prometheus::Client.configuration.multiprocess_files_dir
    old_metrics = Dir[File.join(dir, '*.db')]

    FileUtils.rm_rf(old_metrics)
  end
end

warmup do |app|
  cleanup_prometheus_multiproc_dir

  client = Rack::MockRequest.new(app)
  client.get('/')
end

map ENV['RAILS_RELATIVE_URL_ROOT'] || "/" do
  use Gitlab::Middleware::ReleaseEnv
  run Gitlab::Application
end
