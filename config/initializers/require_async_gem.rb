# frozen_string_literal: true

if RUBY_VERSION >= "3.3"
  # No more such warnings in Ruby 3.3+
  require 'async'
else
  # Silences this warning while requiring async gem:
  # `warning: IO::Buffer is experimental and both the Ruby and C interface may change in the future!`
  # See also https://github.com/socketry/io-event/issues/82
  Kernel.silence_warnings do
    require 'async'
  end
end
