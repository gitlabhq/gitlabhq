ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# set default directory for multiproces metrics gathering
if ENV['RAILS_ENV'] == 'development' || ENV['RAILS_ENV'] == 'test'
  ENV['prometheus_multiproc_dir'] ||= 'tmp/prometheus_multiproc_dir'
end
