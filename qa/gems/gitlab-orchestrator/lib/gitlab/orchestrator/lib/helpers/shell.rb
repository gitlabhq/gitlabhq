# frozen_string_literal: true

require "open3"
require "pty"

module Gitlab
  module Orchestrator
    module Helpers
      # Wrapper for shell command execution
      #
      module Shell
        CommandFailure = Class.new(StandardError)

        # Execute shell command
        #
        # @param [Array] command
        # @param [String] stdin_data
        # @param [Boolean] raise_on_failure
        # @param [Hash] env
        # @param [Boolean] live_output whether to stream output in real-time
        # @return [<String, Array>] return command output and status if raise_on_failure is false
        def execute_shell(cmd, stdin_data: nil, raise_on_failure: true, env: {}, live_output: false)
          raise "System commands must be given as an array of strings" unless cmd.is_a?(Array)

          if cmd.one? && cmd.first.match?(/\s/)
            raise "System commands must be split into an array of space-separated values"
          end

          output = ""
          status = nil

          if live_output
            begin
              PTY.spawn(env, *cmd) do |stdout, stdin, pid|
                if stdin_data
                  stdin.write(stdin_data)
                  stdin.close
                end

                begin
                  stdout.each_line do |line|
                    print line
                    output += line
                  end
                rescue Errno::EIO
                end

                _, status = Process.waitpid2(pid)
              end
            rescue PTY::ChildExited => e
              status = e.status
            end
          else
            output, status = Open3.popen2e(env, *cmd) do |stdin, stdin_and_stderr, wait_thr|
              if stdin_data
                stdin.write(stdin_data)
                stdin.close
              end

              [stdin_and_stderr.read, wait_thr.value]
            end
          end

          if raise_on_failure && !status.success?
            err_msg = "Command '#{cmd.join(' ')}' failed!\n#{output}"
            raise(CommandFailure, err_msg)
          end

          raise_on_failure ? output : [output, status]
        end
      end
    end
  end
end
