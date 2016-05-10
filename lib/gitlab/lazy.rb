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

    def method_missing(name, *args, &block)
      @result = @block.call unless defined?(@result)

      @result.__send__(name, *args, &block)
    end
  end
end
