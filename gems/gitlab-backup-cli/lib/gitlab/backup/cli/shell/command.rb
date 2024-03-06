# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Shell
        # Abstraction to control shell command execution
        # It provides an easier API to common usages
        class Command
          attr_reader :cmd_args, :env

          # Result data structure from running a command
          #
          # @attr [String] stdout
          # @attr [String] stderr
          # @attr [Process::Status] status
          # @attr [Float] duration
          Result = Struct.new(:stdout, :stderr, :status, :duration, keyword_init: true)

          # @example Usage
          #   Shell.new('echo', 'Some amazing output').capture
          # @param [Array<String>] cmd_args
          # @param [Hash<String,String>] env
          def initialize(*cmd_args, env: {})
            @cmd_args = cmd_args
            @env = env
          end

          # Execute a process and return its output and status
          #
          # @return [Command::Result] Captured output from executing a process
          def capture
            start = Time.now
            stdout, stderr, status = Open3.capture3(env, *cmd_args)
            duration = Time.now - start

            Result.new(stdout: stdout, stderr: stderr, status: status, duration: duration)
          end
        end
      end
    end
  end
end
