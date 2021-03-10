# frozen_string_literal: true

require 'spec_helper'

RSpec.configure do |config|
  # Redirect stdout so specs don't have so much noise
  config.before(:all) do
    $stdout = StringIO.new
  end

  # Reset stdout
  config.after(:all) do
    $stdout = STDOUT
  end
end
