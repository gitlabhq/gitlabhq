require 'prometheus/client'

Prometheus::Client.configure do |config|
  config.logger = Rails.logger

  config.initial_mmap_file_size = 4 * 1024
  config.multiprocess_files_dir = ENV['prometheus_multiproc_dir']

  if Rails.env.development? && Rails.env.test?
    config.multiprocess_files_dir ||= Rails.root.join('tmp/prometheus_multiproc_dir')
  end
end
