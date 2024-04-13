# frozen_string_literal: true

RSpec.configure do |config|
  # Allows stdout to be redirected to reduce noise
  config.before(:each, :silence_output) do
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  config.after(:each, :silence_output) do
    $stdout = STDOUT
    $stderr = STDERR
  end
end
