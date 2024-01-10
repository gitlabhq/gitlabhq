# frozen_string_literal: true

if $LOADED_FEATURES.include?(File.expand_path('spec_helper.rb', __dir__))
  # There's no need to load anything here if spec_helper is already loaded
  # because spec_helper is more extensive than fast_spec_helper
  return
end

require_relative '../config/bundler_setup'

ENV['IN_MEMORY_APPLICATION_SETTINGS'] = 'true'

require './spec/deprecation_warnings'

# Enable zero monkey patching mode before loading any other RSpec code.
RSpec.configure(&:disable_monkey_patching!)

require 'active_support/all'
require 'pry'
require 'gitlab/utils/all'
require_relative 'rails_autoload'

require_relative '../config/settings'
require_relative 'support/rspec'
require_relative '../lib/gitlab'

require_relative 'simplecov_env'
SimpleCovEnv.start!

ActiveSupport::XmlMini.backend = 'Nokogiri'

# Consider tweaking configuration in `spec/support/rspec.rb` which is also
# used by `spec/spec_helper.rb`.

require_relative('../jh/spec/fast_spec_helper') if Gitlab.jh?
