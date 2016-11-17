module Gitlab
  module ChatCommands
    class Command < BaseCommand
      COMMANDS = [
        Gitlab::ChatCommands::IssueShow,
        Gitlab::ChatCommands::IssueSearch,
        Gitlab::ChatCommands::IssueCreate,

        Gitlab::ChatCommands::MergeRequestShow,
        Gitlab::ChatCommands::MergeRequestSearch,
      ].freeze

      def execute
        klass, match = fetch_klass

        return help(help_messages, params[:command]) unless klass.try(:available?, project)

        klass.new(project, current_user, params).execute(match)
      end

      private

      def fetch_klass
        match = nil
        service = available_commands.find do |klass|
          match = klass.match(command)
        end

        [service, match]
      end

      def help_messages
        available_commands.map do |klass|
          klass.help_message
        end
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
