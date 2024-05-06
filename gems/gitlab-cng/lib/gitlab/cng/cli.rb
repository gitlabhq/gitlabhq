# frozen_string_literal: true

require "thor"
require "require_all"

require_rel "helpers/**/*.rb"
require_rel "commands/**/*.rb"

module Gitlab
  module Cng
    # Main CLI class handling all commands
    #
    class CLI < Thor
      # Error raised by this runner
      Error = Class.new(StandardError)

      # Fail if unknown option is passed
      check_unknown_options!

      class << self
        # Exit with non 0 status code if any command fails
        #
        # @return [Boolean]
        def exit_on_failure?
          true
        end

        # Register all public methods of Thor class as top level commands
        #
        # @param [Thor] klass
        # @return [void]
        def register_commands(klass)
          raise Error, "#{klass} is not a Thor class" unless klass < Thor

          klass.commands.each do |name, command|
            raise Error, "Tried to register command '#{name}' but the command already exists" if commands[name]

            # check if the method takes arguments
            pass_args = klass.new.method(name).arity != 0

            commands[name] = command
            define_method(name) do |*args|
              pass_args ? invoke(klass, name, *args) : invoke(klass, name)
            end
          end
        end
      end

      register_commands(Commands::Version)
      register_commands(Commands::Doctor)
    end
  end
end
