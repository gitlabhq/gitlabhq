require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

# set default directory for multiproces metrics gathering
if ENV['RAILS_ENV'] == 'development' || ENV['RAILS_ENV'] == 'test'
  ENV['prometheus_multiproc_dir'] ||= 'tmp/prometheus_multiproc_dir'
end
