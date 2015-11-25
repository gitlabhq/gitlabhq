if ENV['USE_PUMA']
  require 'puma'
  require 'puma_worker_killer'

  if Rails.env.production? or Rails.env.staging?
    PumaWorkerKiller.config do |config|
      config.ram       = 250
      config.frequency = 5

      # We just wan't to limit to a fixed maximum, unrelated to the total amount
      # of available RAM.
      config.percent_usage = 100.0

      # Ideally we'll never hit the maximum amount of memory. If so the worker
      # is restarted already, thus periodically restarting workers shouldn't be
      # needed.
      config.rolling_restart_frequency = false
    end

    PumaWorkerKiller.start
  end
end
