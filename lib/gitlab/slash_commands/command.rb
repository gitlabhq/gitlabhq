module Gitlab
  module SlashCommands
    class Command < BaseCommand
      COMMANDS = [
        Gitlab::SlashCommands::IssueShow,
        Gitlab::SlashCommands::IssueNew,
        Gitlab::SlashCommands::IssueSearch,
        Gitlab::SlashCommands::IssueMove,
        Gitlab::SlashCommands::Deploy
      ].freeze

      def execute
        command, match = match_command

        if command
          if command.allowed?(project, current_user)
            command.new(project, chat_name, params).execute(match)
          else
            Gitlab::SlashCommands::Presenters::Access.new.access_denied
          end
        else
          Gitlab::SlashCommands::Help.new(project, chat_name, params)
            .execute(available_commands, params[:text])
        end
      end

      def match_command
        match = nil
        service =
          available_commands.find do |klass|
            match = klass.match(params[:text])
          end

        [service, match]
      end

      private

      def available_commands
        COMMANDS.select do |klass|
          klass.available?(project)
        end
      end
    end
  end
end
