# frozen_string_literal: true

#  $" is $LOADED_FEATURES, but RuboCop didn't like it
if $".include?(File.expand_path('spec_helper.rb', __dir__))
  # There's no need to load anything here if spec_helper is already loaded
  # because spec_helper is more extensive than fast_spec_helper
  return
end

require 'bundler/setup'

ENV['GITLAB_ENV'] = 'test'
ENV['IN_MEMORY_APPLICATION_SETTINGS'] = 'true'

require 'active_support/dependencies'
require_relative '../config/initializers/0_inject_enterprise_edition_module'
require_relative '../config/settings'
require_relative 'support/rspec'
require 'active_support/all'

ActiveSupport::Dependencies.autoload_paths << 'lib'
ActiveSupport::Dependencies.autoload_paths << 'ee/lib'

ActiveSupport::XmlMini.backend = 'Nokogiri'
