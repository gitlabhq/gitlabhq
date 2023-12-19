# frozen_string_literal: true

require_relative '../qa'

require_relative 'scenario_shared_examples'
require_relative('../../jh/qa/spec/spec_helper') if GitlabEdition.jh?

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.max_formatted_output_length = nil
  end
end
