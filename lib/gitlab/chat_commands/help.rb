module Gitlab
  module ChatCommands
    class Help < IssueCommand
      # This class has to be used last, as it always matches. It has to match
      # because other commands were not triggered and we want to show the help
      # command
      def self.match(_)
        true
      end

      def self.help_message
        'help'
      end

      def self.allowed?(_project, _user)
        true
      end

      def execute(_)
        commands = caller.first.available_commands

        Gitlab::ChatCommands::Presenters::Help.new(commands).execute
      end
    end
  end
end
