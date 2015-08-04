# This file is used by Rack-based servers to start the application.

if defined?(Unicorn)
  require 'unicorn'

  if ENV['RAILS_ENV'] == 'production' || ENV['RAILS_ENV'] == 'staging'
    # Unicorn self-process killer
    require 'unicorn/worker_killer'

    # Max memory size (RSS) per worker
    use Unicorn::WorkerKiller::Oom, (200 * (1 << 20)), (250 * (1 << 20))
  end
end

require ::File.expand_path('../config/environment',  __FILE__)

map ENV['RAILS_RELATIVE_URL_ROOT'] || "/" do
  run Gitlab::Application
end
