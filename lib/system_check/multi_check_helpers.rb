# frozen_string_literal: true

module SystemCheck
  # Helpers used inside a SystemCheck instance to standardize output responses
  # when using a multi_check version
  module MultiCheckHelpers
    def print_skipped(reason)
      say Rainbow('skipped').magenta

      say Rainbow('  Reason:').blue
      say "  #{reason}"
    end

    def print_warning(reason)
      say Rainbow('warning').magenta

      say Rainbow('  Reason:').blue
      say "  #{reason}"
    end

    def print_failure(reason)
      say Rainbow('no').red

      say Rainbow('  Reason:').blue
      say "  #{reason}"
    end

    def print_pass
      say Rainbow(self.class.check_pass).green
    end
  end
end
