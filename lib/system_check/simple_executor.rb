# frozen_string_literal: true

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
      print_display_name(check_klass)

      check = check_klass.new

      # When implements skip method, we run it first, and if true, skip the check
      if check.can_skip? && check.skip?
        say Rainbow(check.skip_reason || check_klass.skip_reason).magenta
        return
      end

      # When implements a multi check, we don't control the output
      if check.multi_check?
        check.multi_check
        return
      end

      if check.check?
        print_check_pass(check_klass)
      else
        print_check_failure(check_klass)

        if check.can_repair?
          print 'Trying to fix error automatically. ...' # rubocop:disable Rails/Output -- system check CLI output

          if check.repair!
            print_success
            return
          else
            print_failure
          end
        end

        check.show_error
      end
    rescue StandardError => e
      say Rainbow("Exception: #{e.message}").red
    end

    private

    def say(message = '')
      puts message # rubocop:disable Rails/Output -- system check CLI output
    end

    def print_display_name(check_klass)
      print "#{check_klass.display_name} ... " # rubocop:disable Rails/Output -- system check CLI output
    end

    def print_check_pass(check_klass)
      say Rainbow(check_klass.check_pass).green
    end

    def print_check_failure(check_klass)
      say Rainbow(check_klass.check_fail).red
    end

    def print_success
      say Rainbow('Success').green
    end

    def print_failure
      say Rainbow('Failed').red
    end

    # Prints header content for the series of checks to be executed for this component
    #
    # @param [String] component name of the component relative to the checks being executed
    def start_checking(component)
      say "Checking #{Rainbow(component).yellow} ..."
      say ''
    end

    # Prints footer content for the series of checks executed for this component
    #
    # @param [String] component name of the component relative to the checks being executed
    def finished_checking(component)
      say ''
      say "Checking #{Rainbow(component).yellow} ... #{Rainbow('Finished').green}"
      say ''
    end
  end
end
