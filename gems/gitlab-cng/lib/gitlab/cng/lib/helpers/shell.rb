# frozen_string_literal: true

require "open3"

module Gitlab
  module Cng
    module Helpers
      # Wrapper for shell command execution
      #
      module Shell
        CommandFailure = Class.new(StandardError)

        # Execute shell command
        #
        # @param [Array] command
        # @param [Boolean] raise_on_failure
        # @param [Hash] env
        # @return [<String, Array>] return command output and status if raise_on_failure is false
        def execute_shell(cmd, raise_on_failure: true, env: {})
          raise "System commands must be given as an array of strings" unless cmd.is_a?(Array)

          if cmd.one? && cmd.first.match?(/\s/)
            raise "System commands must be split into an array of space-separated values"
          end

          out, status = Open3.capture2e(env, *cmd)

          if raise_on_failure && !status.success?
            err_msg = "Command '#{cmd}' failed!\n#{out}"
            raise(CommandFailure, err_msg)
          end

          raise_on_failure ? out : [out, status]
        end
      end
    end
  end
end
