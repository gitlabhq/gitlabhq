# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Utils
        class Rake
          # @return [Array<String>] a list of tasks to be executed
          attr_reader :tasks

          # @return [String|Pathname] a path where rake tasks are run from
          attr_reader :chdir

          # @param [Array<String>] *tasks a list of tasks to be executed
          # @param [String|Pathname] chdir a path where rake tasks are run from
          def initialize(*tasks, chdir: Gitlab::Backup::Cli.root)
            @tasks = tasks
            @chdir = chdir
          end

          # Execute the rake task and return its execution result status
          #
          # @return [self]
          def execute
            Bundler.with_original_env do
              @result = Shell::Command.new(*rake_command, chdir: chdir).capture
            end

            self
          end

          # Execute the rake task and intercept its output line by line including a final result status
          #
          # @example Usage
          #    Rake.new('some:task').capture_each { |stream, output| puts output if stream == :stdout }
          # @yield |stream, output| Return output from :stdout or :stderr stream line by line
          # @yieldparam [Symbol] stream type (either :stdout or :stderr)
          # @yieldparam [String] output content
          # @return [Gitlab::Backup::Cli::Command::Result] -- Captured output from executing a process
          def capture_each(&block)
            Bundler.with_original_env do
              @result = Shell::Command.new(*rake_command, chdir: chdir).capture_each(&block)
            end

            self
          end

          # Return whether the execution was a success or not
          #
          # @return [Boolean] whether the execution was a success
          def success?
            @result&.status&.success? || false
          end

          # Return the captured rake output
          #
          # @return [String] stdout content
          def output
            @result&.stdout || ''
          end

          # Return the captured error content
          #
          # @return [String] stdout content
          def stderr
            @result&.stderr || ''
          end

          # Return the captured execution duration
          #
          # @return [Float] execution duration
          def duration
            @result&.duration || 0.0
          end

          private

          # Return a list of commands necessary to execute `rake`
          #
          # @return [Array<String (frozen)>] array of commands to be used by Shellout
          def rake_command
            %w[bundle exec rake] + tasks
          end
        end
      end
    end
  end
end
