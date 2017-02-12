module SystemCheck
  class BaseExecutor
    attr_reader :checks
    attr_reader :component

    def initialize(component)
      raise ArgumentError unless component.is_a? String

      @component = component
      @checks = Set.new
    end

    def <<(check)
      raise ArgumentError unless check.is_a? BaseCheck
      @checks << check
    end
  end
end
