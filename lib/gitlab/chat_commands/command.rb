module Gitlab
  module ChatCommands
    class Command < BaseCommand
      include Presenters::Command

      COMMANDS = [
        Gitlab::ChatCommands::IssueShow,
        Gitlab::ChatCommands::IssueCreate,
        Gitlab::ChatCommands::IssueSearch,
        Gitlab::ChatCommands::Deploy,
      ].freeze

      def execute
        command, match = match_command

        if command
          if command.allowed?(project, current_user)
            command.new(project, current_user, params).execute(match)
          else
            access_denied
          end
        else
          help_message
        end
      end

      private

      def match_command
        match = nil
        service = available_commands.find do |klass|
          match = klass.match(command)
        end

        [service, match]
      end

      def available_commands
        COMMANDS.select do |klass|
          klass.available?(project)
        end
      end

      def command
        params[:text]
      end
    end
  end
end
