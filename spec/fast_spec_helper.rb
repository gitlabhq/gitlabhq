require 'bundler/setup'

require 'settingslogic'

ENV["RAILS_ENV"] = 'test'
ENV["IN_MEMORY_APPLICATION_SETTINGS"] = 'true'

unless Kernel.respond_to?(:require_dependency)
  module Kernel
    alias_method :require_dependency, :require
  end
end

unless defined?(Rails)
  module Rails
    def self.root
      Pathname.new(File.expand_path(''))
    end

    # Copied from https://github.com/rails/rails/blob/v4.2.10/railties/lib/rails.rb#L59-L61
    def self.env
      @_env ||= ActiveSupport::StringInquirer.new(ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development")
    end
  end
end

# Settings is used in config/initializers/2_app.rb
class Settings < Settingslogic
  source Rails.root.join('config/gitlab.yml')
  namespace Rails.env
end

# Defines Gitlab and Gitlab.config
unless defined?(Gitlab) && Gitlab.respond_to?(:config)
  require_relative '../config/initializers/2_app'
end

require_relative 'support/rspec'
