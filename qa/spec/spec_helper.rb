# frozen_string_literal: true

# Silence logger output for tests and disable colorization
ENV["QA_LOG_LEVEL"] = "FATAL"
ENV["COLORIZED_LOGS"] = "false"

require_relative '../qa'

require_relative 'scenario_shared_examples'
require_relative('../../jh/qa/spec/spec_helper') if GitlabEdition.jh?

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.max_formatted_output_length = nil
  end
end
