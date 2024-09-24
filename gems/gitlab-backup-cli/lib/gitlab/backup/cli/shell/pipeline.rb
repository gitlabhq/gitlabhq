# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Shell
        class Pipeline
          # Result data structure from running a pipeline
          #
          # @attr [String] stderr
          # @attr [Array<Process::Status>] status_list
          # @attr [Float] duration
          Result = Struct.new(:stderr, :status_list, :duration, keyword_init: true) do
            def success?
              return false unless status_list&.any?

              status_list.map(&:success?).all?
            end
          end

          attr_reader :shell_commands

          # @param [Array<Shell::Command>] shell_commands
          def initialize(*shell_commands)
            @shell_commands = shell_commands
          end

          # Run commands in pipeline with optional input or output redirection
          #
          # @param [IO|String|Array] input stdin redirection
          # @param [IO|String|Array] output stdout redirection
          # @return [Pipeline::Result]
          def run!(input: nil, output: nil)
            start = Time.now
            # Open3 writes on `err_write` and we receive from `err_read`
            err_read, err_write = IO.pipe

            # Pipeline accepts custom {Process.spawn} options
            # stderr capture is always performed, stdin and stdout redirection
            # are performed only when either `input` or `output` are present
            options = { err: err_write } # redirect stderr to IO pipe
            options[:in] = input if input # redirect stdin
            options[:out] = output if output # redirect stdout

            status_list = Open3.pipeline(*build_command_list, **options)
            duration = Time.now - start

            err_write.close # close the pipe before reading
            stderr = err_read.read
            err_read.close # close after reading to avoid leaking file descriptors

            Result.new(
              stderr: stderr,
              status_list: status_list,
              duration: duration
            )
          end

          private

          def build_command_list
            @shell_commands.map(&:cmd_args)
          end
        end
      end
    end
  end
end
