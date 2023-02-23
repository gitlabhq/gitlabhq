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

require_relative 'rails_autoload'

require_relative '../config/settings'
require_relative 'support/rspec'
require_relative '../lib/gitlab/utils'
require_relative '../lib/gitlab/utils/strong_memoize'
require 'active_support/all'

require_relative 'simplecov_env'
SimpleCovEnv.start!

ActiveSupport::XmlMini.backend = 'Nokogiri'

RSpec.configure do |config|
  # Makes diffs show entire non-truncated values.
  config.before(:each, unlimited_max_formatted_output_length: true) do |_example|
    config.expect_with :rspec do |c|
      c.max_formatted_output_length = nil
    end
  end
end
