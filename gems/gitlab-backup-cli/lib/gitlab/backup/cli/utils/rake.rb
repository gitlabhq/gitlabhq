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

          # @return [self]
          def execute
            Bundler.with_original_env do
              @result = Shell::Command.new(*rake_command, chdir: chdir).capture
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
