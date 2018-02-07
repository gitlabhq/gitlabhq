# This file is used by Rack-based servers to start the application.

if defined?(Unicorn)
  require 'unicorn'

  if ENV['RAILS_ENV'] == 'production' || ENV['RAILS_ENV'] == 'staging'
    # Unicorn self-process killer
    require 'unicorn/worker_killer'

    min = (ENV['GITLAB_UNICORN_MEMORY_MIN'] || 300 * 1 << 20).to_i
    max = (ENV['GITLAB_UNICORN_MEMORY_MAX'] || 350 * 1 << 20).to_i

    # Max memory size (RSS) per worker
    use Unicorn::WorkerKiller::Oom, min, max
  end
end

require ::File.expand_path('../config/environment',  __FILE__)

warmup do |app|
  client = Rack::MockRequest.new(app)
  client.get('/')
end

map ENV['RAILS_RELATIVE_URL_ROOT'] || "/" do
  use Gitlab::Middleware::ReleaseEnv
  run Gitlab::Application
end
