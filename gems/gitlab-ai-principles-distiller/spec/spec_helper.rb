# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

RSpec.configure do |config|
  config.around do |example|
    original_branch = ENV['CI_DEFAULT_BRANCH']
    ENV['CI_DEFAULT_BRANCH'] ||= 'master'
    example.run
  ensure
    ENV['CI_DEFAULT_BRANCH'] = original_branch
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
