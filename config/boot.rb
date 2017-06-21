require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

# set default directory for multiproces metrics gathering
if ENV['RAILS_ENV'] == 'development' || ENV['RAILS_ENV'] == 'test'
  ENV['prometheus_multiproc_dir'] ||= 'tmp/prometheus_multiproc_dir'
end

# Default Bootsnap configuration from https://github.com/Shopify/bootsnap#usage
require 'bootsnap'
Bootsnap.setup(
  cache_dir:            'tmp/cache',
  development_mode:     ENV['RAILS_ENV'] == 'development',
  load_path_cache:      true,
  autoload_paths_cache: true,
  disable_trace:        false,
  compile_cache_iseq:   true,
  compile_cache_yaml:   true
)
