require 'bundler/setup'

ENV['GITLAB_ENV'] = 'test'
ENV['IN_MEMORY_APPLICATION_SETTINGS'] = 'true'

require_relative '../config/settings'
require_relative 'support/rspec'
require 'active_support/all'

ActiveSupport::Dependencies.autoload_paths << 'lib'
