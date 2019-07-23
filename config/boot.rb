ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# Set up gems listed in the Gemfile.
require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
require 'bootsnap/setup' if ENV['RAILS_ENV'] != 'production' || %w(1 yes true).include?(ENV['ENABLE_BOOTSNAP'])
