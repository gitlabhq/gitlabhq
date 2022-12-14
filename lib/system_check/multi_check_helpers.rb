# frozen_string_literal: true

module SystemCheck
  # Helpers used inside a SystemCheck instance to standardize output responses
  # when using a multi_check version
  module MultiCheckHelpers
    def print_skipped(reason)
      $stdout.puts 'skipped'.color(:magenta)

      $stdout.puts '  Reason:'.color(:blue)
      $stdout.puts "  #{reason}"
    end

    def print_warning(reason)
      $stdout.puts 'warning'.color(:magenta)

      $stdout.puts '  Reason:'.color(:blue)
      $stdout.puts "  #{reason}"
    end

    def print_failure(reason)
      $stdout.puts 'no'.color(:red)

      $stdout.puts '  Reason:'.color(:blue)
      $stdout.puts "  #{reason}"
    end

    def print_pass
      $stdout.puts self.class.check_pass.color(:green)
    end
  end
end
