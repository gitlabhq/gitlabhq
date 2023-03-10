# frozen_string_literal: true

if $LOADED_FEATURES.include?(File.expand_path('spec_helper.rb', __dir__))
  # There's no need to load anything here if spec_helper is already loaded
  # because spec_helper is more extensive than fast_spec_helper
  return
end

require_relative '../config/bundler_setup'

ENV['GITLAB_ENV'] = 'test'
ENV['IN_MEMORY_APPLICATION_SETTINGS'] = 'true'

# Enable zero monkey patching mode before loading any other RSpec code.
RSpec.configure(&:disable_monkey_patching!)

require 'active_support/dependencies'
require_relative '../config/initializers/0_inject_enterprise_edition_module'
require_relative '../config/settings'
require_relative 'support/rspec'
require_relative '../lib/gitlab/utils'
require_relative '../lib/gitlab/utils/strong_memoize'
require 'active_support/all'
require 'pry'

require_relative 'simplecov_env'
SimpleCovEnv.start!

unless ActiveSupport::Dependencies.autoload_paths.frozen?
  ActiveSupport::Dependencies.autoload_paths << 'lib'
  ActiveSupport::Dependencies.autoload_paths << 'ee/lib'
  ActiveSupport::Dependencies.autoload_paths << 'jh/lib'
end

ActiveSupport::XmlMini.backend = 'Nokogiri'

RSpec.configure do |config|
  # Makes diffs show entire non-truncated values.
  config.before(:each, unlimited_max_formatted_output_length: true) do |_example|
    config.expect_with :rspec do |c|
      c.max_formatted_output_length = nil
    end
  end
end
