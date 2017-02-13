module SystemCheck
  # @attr_reader [Array<BaseCheck>] checks classes of corresponding checks to be executed in the same order
  # @attr_reader [String] component name of the component relative to the checks being executed
  class BaseExecutor
    attr_reader :checks
    attr_reader :component

    # @param [String] component name of the component relative to the checks being executed
    def initialize(component)
      raise ArgumentError unless component.is_a? String

      @component = component
      @checks = Set.new
    end

    # Add a check to be executed
    #
    # @param [BaseCheck] check class
    def <<(check)
      raise ArgumentError unless check.is_a? BaseCheck
      @checks << check
    end
  end
end
