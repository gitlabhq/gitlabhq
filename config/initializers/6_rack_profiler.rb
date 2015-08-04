if Rails.env.development?
  require 'rack-mini-profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)

  Rack::MiniProfiler.config.position = 'right'
  Rack::MiniProfiler.config.start_hidden = false
  Rack::MiniProfiler.config.skip_paths << '/teaspoon'
end
