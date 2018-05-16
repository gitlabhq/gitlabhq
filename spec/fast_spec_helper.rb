require 'bundler/setup'

ENV['GITLAB_ENV'] = 'test'
ENV['IN_MEMORY_APPLICATION_SETTINGS'] = 'true'

unless Object.respond_to?(:require_dependency)
  class Object
    alias_method :require_dependency, :require
  end
end

# Defines Settings and Gitlab.config which are at the center of the app
require_relative '../config/settings'
require_relative '../lib/gitlab' unless defined?(Gitlab.config)

require_relative 'support/rspec'
