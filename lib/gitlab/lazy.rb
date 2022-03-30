# frozen_string_literal: true

module Gitlab
  # A class that can be wrapped around an expensive method call so it's only
  # executed when actually needed.
  #
  # Usage:
  #
  #     object = Gitlab::Lazy.new { some_expensive_work_here }
  #
  #     object['foo']
  #     object.bar
  class Lazy < BasicObject
    def initialize(&block)
      @block = block
    end

    def method_missing(...)
      __evaluate__

      @result.__send__(...) # rubocop:disable GitlabSecurity/PublicSend
    end

    def respond_to_missing?(name, include_private = false)
      __evaluate__

      @result.respond_to?(name, include_private) || super
    end

    private

    def __evaluate__
      @result = @block.call unless defined?(@result)
    end
  end
end
