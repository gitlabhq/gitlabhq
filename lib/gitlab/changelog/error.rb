# frozen_string_literal: true

module Gitlab
  module Changelog
    # An error raised when a changelog couldn't be generated.
    Error = Class.new(StandardError)
  end
end
