# frozen_string_literal: true

require "thor"
require "require_all"
require "uri"
require "tty-prompt"

# make sure helpers are required first
require_rel "lib/helpers/**/*.rb"
require_rel "lib/**/*.rb"
require_rel "commands/**/*.rb"

module Gitlab
  module Cng
    # Main CLI class handling all commands
    #
    class CLI < Commands::Command
      extend Helpers::Thor

      # Error raised by this runner
      Error = Class.new(StandardError)

      # Exit with non 0 status code if any command fails
      #
      # @return [Boolean]
      def self.exit_on_failure?
        true
      end

      register_commands(Commands::Version)
      register_commands(Commands::Doctor)

      desc "create [SUBCOMMAND]", "Manage deployment related object creation"
      subcommand "create", Commands::Create

      desc "log [SUBCOMMAND]", "Manage deployment related logs"
      subcommand "log", Commands::Log

      desc "destroy [SUBCOMMAND]", "Manage deployment related object cleanup"
      subcommand "destroy", Commands::Destroy
    end
  end
end
