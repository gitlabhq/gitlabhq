module SystemCheck
  def self.run(component, checks = {}, executor_klass = SimpleExecutor)
    unless executor_klass.is_a? BaseExecutor
      raise ArgumentError, 'Invalid executor'
    end

    executor = executor_klass.new(component)
    executor.checks = checks.map do |check|
      raise ArgumentError unless check.is_a? BaseCheck
    end
  end
end
