# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Flags direct writes to `$stdout`, `$stderr`, `STDOUT`, or `STDERR`.
      #
      # @example
      #
      #   # bad
      #   $stdout.puts("Checking LDAP ...")
      #   $stderr.puts("Error: #{message}")
      #   STDOUT.print("done")
      #   STDERR.print("done")
      #
      #   # good
      #   Gitlab::AppLogger.info("Checking LDAP ...")
      #   say("Checking LDAP ...") # via Gitlab::TaskHelpers or SystemCheck::Helpers
      #
      class DirectStdio < ::RuboCop::Cop::Base
        MSG = 'Do not write to `stdout` or `stderr`. ' \
          'Use a structured JSON logger or an output wrapper method instead. ' \
          'https://docs.gitlab.com/development/logging.html'

        GLOBAL_VARS = %i[$stdout $stderr].to_set
        CONST_VARS = %i[STDOUT STDERR].to_set

        # @!method io_output?(node)
        def_node_matcher :io_output?, <<~PATTERN
          (call
            {
              (gvar GLOBAL_VARS)
              (const nil? CONST_VARS)
            }
            {:puts :print}
            ...)
        PATTERN

        def on_send(node)
          add_offense(node) if io_output?(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
