# frozen_string_literal: true

module SystemCheck
  # Helpers used inside a SystemCheck instance to standardize output responses
  # when using a multi_check version
  module MultiCheckHelpers
    def print_skipped(reason)
      $stdout.puts Rainbow('skipped').magenta

      $stdout.puts Rainbow('  Reason:').blue
      $stdout.puts "  #{reason}"
    end

    def print_warning(reason)
      $stdout.puts Rainbow('warning').magenta

      $stdout.puts Rainbow('  Reason:').blue
      $stdout.puts "  #{reason}"
    end

    def print_failure(reason)
      $stdout.puts Rainbow('no').red

      $stdout.puts Rainbow('  Reason:').blue
      $stdout.puts "  #{reason}"
    end

    def print_pass
      $stdout.puts Rainbow(self.class.check_pass).green
    end
  end
end
