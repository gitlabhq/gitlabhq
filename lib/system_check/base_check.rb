module SystemCheck
  # Base class for Checks. You must inherit from here
  # and implement the methods below when necessary
  class BaseCheck
    # This is where you should implement the main logic that will return
    # a boolean at the end
    #
    # You should not print any output to STDOUT here, use the specific methods instead
    #
    # @return [Boolean] whether the check passed or not
    def check?
      raise NotImplementedError
    end

    # This is where you should print detailed information for any error found during #check?
    #
    # You may use helper methods to help format the output:
    #
    # @see #try_fixing_it
    # @see #fix_and_rerun
    # @see #for_more_infromation
    def show_error
      raise NotImplementedError
    end

    # If skip returns true, than no other method on this check will be executed
    #
    # @return [Boolean] whether or not this check should be skipped
    def skip?
      false
    end

    # If you enabled #skip? here is where you define a custom message explaining why
    #
    # Do not print anything to STDOUT, return a string.
    #
    # @return [String] message why this check was skipped
    def skip_message
    end

    protected

    # Display a formatted list of instructions on how to fix the issue identified by the #check?
    #
    # @param [Array<String>] steps one or short sentences with help how to fix the issue
    def try_fixing_it(*steps)
      steps = steps.shift if steps.first.is_a?(Array)

      $stdout.puts '  Try fixing it:'.color(:blue)
      steps.each do |step|
        $stdout.puts "  #{step}"
      end
    end

    # Display a message telling to fix and rerun the checks
    def fix_and_rerun
      $stdout.puts '  Please fix the error above and rerun the checks.'.color(:red)
    end

    # Display a formatted list of references (documentation or links) where to find more information
    #
    # @param [Array<String>] sources one or more references (documentation or links)
    def for_more_information(*sources)
      sources = sources.shift if sources.first.is_a?(Array)

      $stdout.puts '  For more information see:'.color(:blue)
      sources.each do |source|
        $stdout.puts '  #{source}'
      end
    end
  end
end
