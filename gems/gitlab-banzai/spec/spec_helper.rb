# frozen_string_literal: true

require 'rspec-parameterized'
require 'active_support/notifications'

require 'banzai/all'
require 'gitlab/utils/eq_html_matcher'

require_relative 'support/filter_spec_helper'
require_relative 'support/filter_shared_examples'
require_relative 'support/sanitization_shared_examples'

RSpec.configure do |config|
  # Matches the monolith (spec/support/rspec.rb). RSpec defaults this to true,
  # which locks a mutex on every `let` read.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/379686
  config.threadsafe = false

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    Banzai.configure do |banzai|
      banzai.timeout_disabled = false
      banzai.with_timeout = ->(_seconds, &block) { block.call }
      banzai.track_exception = ->(_exception, **_extra) {}
    end
  end
end
