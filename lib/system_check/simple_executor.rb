module SystemCheck
  # Simple Executor is current default executor for GitLab
  # It is a simple port from display logic in the old check.rake
  #
  # There is no concurrency level and the output is progressively
  # printed into the STDOUT
  class SimpleExecutor < BaseExecutor
    # Executes defined checks in the specified order and outputs confirmation or error information
    def execute
      start_checking(component)

      @checks.each do |check|
        $stdout.print "#{check.name}"
        if check.skip?
          $stdout.puts "skipped #{'(' + skip_message + ')' if skip_message}".color(:magenta)
        elsif check.check?
          $stdout.puts 'yes'.color(:green)
        else
          $stdout.puts 'no'.color(:red)
          check.show_error
        end
      end

      finished_checking(component)
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
