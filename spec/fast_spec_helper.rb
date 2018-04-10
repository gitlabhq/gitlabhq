require 'bundler/setup'

require 'settingslogic'

ENV['GITLAB_ENV'] = 'test'
ENV['RAILS_ENV'] = 'test'
ENV['IN_MEMORY_APPLICATION_SETTINGS'] = 'true'

unless Kernel.respond_to?(:require_dependency)
  module Kernel
    alias_method :require_dependency, :require
  end
end

# Defines Gitlab and Gitlab.config which are at the center of the app
unless defined?(Gitlab) && Gitlab.respond_to?(:config)
  require_relative '../lib/settings'
  require_relative '../config/initializers/2_app'
end

require_relative 'support/rspec'
