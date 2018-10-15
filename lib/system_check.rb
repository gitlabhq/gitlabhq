# frozen_string_literal: true

# Library to perform System Checks
#
# Every Check is implemented as its own class inherited from SystemCheck::BaseCheck
# Execution coordination and boilerplate output is done by the SystemCheck::SimpleExecutor
#
# This structure decouples checks from Rake tasks and facilitates unit-testing
module SystemCheck
  # Executes a bunch of checks for specified component
  #
  # @param [String] component name of the component relative to the checks being executed
  # @param [Array<BaseCheck>] checks classes of corresponding checks to be executed in the same order
  def self.run(component, checks = [])
    executor = SimpleExecutor.new(component)

    checks.each do |check|
      executor << check
    end

    executor.execute
  end
end
