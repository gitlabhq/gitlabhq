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

if defined?(Puma)
  require 'puma'

  if ENV['RAILS_ENV'] == 'production' || ENV['RAILS_ENV'] == 'staging'
    # Puma self-process killer
    require 'puma_worker_killer'

    # Max memory size (RSS) per worker
    PumaWorkerKiller.config do |config|
      config.ram = 250 # RSS limit in MB
      config.frequency = 30 # period check seconds
      config.percent_usage = 0.93 # max percentage
      config.rolling_restart_frequency = (1 * 3600).to_i # restart every 1 hour
    end
    PumaWorkerKiller.start
  end
end

require ::File.expand_path('../config/environment',  __FILE__)

map ENV['RAILS_RELATIVE_URL_ROOT'] || "/" do
  run Gitlab::Application
end
