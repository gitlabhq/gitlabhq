module SystemCheck
  # Base class for Checks. You must inherit from here
  # and implement the methods below when necessary
  class BaseCheck
    include ::SystemCheck::Helpers

    # Define a custom term for when check passed
    #
    # @param [String] term used when check passed (default: 'yes')
    def self.set_check_pass(term)
      @check_pass = term
    end

    # Define a custom term for when check failed
    #
    # @param [String] term used when check failed (default: 'no')
    def self.set_check_fail(term)
      @check_fail = term
    end

    # Define the name of the SystemCheck that will be displayed during execution
    #
    # @param [String] name of the check
    def self.set_name(name)
      @name = name
    end

    # Define the reason why we skipped the SystemCheck
    #
    # This is only used if subclass implements `#skip?`
    #
    # @param [String] reason to be displayed
    def self.set_skip_reason(reason)
      @skip_reason = reason
    end

    # Term to be displayed when check passed
    #
    # @return [String] term when check passed ('yes' if not re-defined in a subclass)
    def self.check_pass
      call_or_return(@check_pass) || 'yes'
    end

    ## Term to be displayed when check failed
    #
    # @return [String] term when check failed ('no' if not re-defined in a subclass)
    def self.check_fail
      call_or_return(@check_fail) || 'no'
    end

    # Name of the SystemCheck defined by the subclass
    #
    # @return [String] the name
    def self.display_name
      call_or_return(@name) || self.name
    end

    # Skip reason defined by the subclass
    #
    # @return [String] the reason
    def self.skip_reason
      call_or_return(@skip_reason) || 'skipped'
    end

    # Define a reason why we skipped the SystemCheck (during runtime)
    #
    # This is used when you need dynamic evaluation like when you have
    # multiple reasons why a check can fail
    #
    # @param [String] reason to be displayed
    def skip_reason=(reason)
      @skip_reason = reason
    end

    # Skip reason defined during runtime
    #
    # This value have precedence over the one defined in the subclass
    #
    # @return [String] the reason
    def skip_reason
      @skip_reason
    end

    # Does the check support automatically repair routine?
    #
    # @return [Boolean] whether check implemented `#repair!` method or not
    def can_repair?
      self.class.instance_methods(false).include?(:repair!)
    end

    def can_skip?
      self.class.instance_methods(false).include?(:skip?)
    end

    def multi_check?
      self.class.instance_methods(false).include?(:multi_check)
    end

    # Execute the check routine
    #
    # This is where you should implement the main logic that will return
    # a boolean at the end
    #
    # You should not print any output to STDOUT here, use the specific methods instead
    #
    # @return [Boolean] whether check passed or failed
    def check?
      raise NotImplementedError
    end

    # Execute a custom check that cover multiple unities
    #
    # When using multi_check you have to provide the output yourself
    def multi_check
      raise NotImplementedError
    end

    # Prints troubleshooting instructions
    #
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

    # When implemented by a subclass, will attempt to fix the issue automatically
    def repair!
      raise NotImplementedError
    end

    # When implemented by a subclass, will evaluate whether check should be skipped or not
    #
    # @return [Boolean] whether or not this check should be skipped
    def skip?
      raise NotImplementedError
    end

    def self.call_or_return(input)
      input.respond_to?(:call) ? input.call : input
    end
    private_class_method :call_or_return
  end
end
