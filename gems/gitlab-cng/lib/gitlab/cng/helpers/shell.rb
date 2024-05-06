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
        # @param [String] command
        # @return [String] output
        def self.execute_shell(command)
          out, err, status = Open3.capture3(command)

          cmd_output = []
          cmd_output << "Out: #{out}" unless out.empty?
          cmd_output << "Err: #{err}" unless err.empty?
          output = cmd_output.join("\n")

          unless status.success?
            err_msg = "Command '#{command}' failed!\n#{output}"
            raise(CommandFailure, err_msg)
          end

          output
        end
      end
    end
  end
end
