module SystemCheck
  # Simple Executor is current default executor for GitLab
  # It is a simple port from display logic in the old check.rake
  #
  # There is no concurrency level and the output is progressively
  # printed into the STDOUT
  #
  # @attr_reader [Array<BaseCheck>] checks classes of corresponding checks to be executed in the same order
  # @attr_reader [String] component name of the component relative to the checks being executed
  class SimpleExecutor
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
      raise ArgumentError unless check.is_a?(Class) && check < BaseCheck

      @checks << check
    end

    # Executes defined checks in the specified order and outputs confirmation or error information
    def execute
      start_checking(component)

      @checks.each do |check|
        run_check(check)
      end

      finished_checking(component)
    end

    # Executes a single check
    #
    # @param [SystemCheck::BaseCheck] check_klass
    def run_check(check_klass)
      $stdout.print "#{check_klass.display_name} ... "

      check = check_klass.new

      # When implements skip method, we run it first, and if true, skip the check
      if check.can_skip? && check.skip?
        $stdout.puts check.skip_reason.try(:color, :magenta) || check_klass.skip_reason.color(:magenta)
        return
      end

      # When implements a multi check, we don't control the output
      if check.multi_check?
        check.multi_check
        return
      end

      if check.check?
        $stdout.puts check_klass.check_pass.color(:green)
      else
        $stdout.puts check_klass.check_fail.color(:red)

        if check.can_repair?
          $stdout.print 'Trying to fix error automatically. ...'

          if check.repair!
            $stdout.puts 'Success'.color(:green)
            return
          else
            $stdout.puts 'Failed'.color(:red)
          end
        end

        check.show_error
      end
    rescue StandardError => e
      $stdout.puts "Exception: #{e.message}".color(:red)
    end

    private

    # Prints header content for the series of checks to be executed for this component
    #
    # @param [String] component name of the component relative to the checks being executed
    def start_checking(component)
      $stdout.puts "Checking #{component.color(:yellow)} ..."
      $stdout.puts ''
    end

    # Prints footer content for the series of checks executed for this component
    #
    # @param [String] component name of the component relative to the checks being executed
    def finished_checking(component)
      $stdout.puts ''
      $stdout.puts "Checking #{component.color(:yellow)} ... #{'Finished'.color(:green)}"
      $stdout.puts ''
    end
  end
end
