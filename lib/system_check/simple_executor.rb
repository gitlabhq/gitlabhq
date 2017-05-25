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
        run_check(check)
      end

      finished_checking(component)
    end

    # Executes a single check
    #
    # @param [SystemCheck::BaseCheck] check
    def run_check(check)
      $stdout.print "#{check.display_name} ... "

      c = check.new

      # When implements skip method, we run it first, and if true, skip the check
      if c.can_skip? && c.skip?
        $stdout.puts check.skip_reason.color(:magenta)
        return
      end
      
      # When implements a multi check, we don't control the output
      if c.is_multi_check?
        c.multi_check
        return
      end

      if c.check?
        $stdout.puts check.check_pass.color(:green)
      else
        $stdout.puts check.check_fail.color(:red)

        if c.can_repair?
          $stdout.print 'Trying to fix error automatically. ...'
          if c.repair!
            $stdout.puts 'Success'.color(:green)
            return
          else
            $stdout.puts 'Failed'.color(:red)
          end
        end

        c.show_error
      end
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
