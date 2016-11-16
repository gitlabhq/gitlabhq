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

        return help(help_messages) unless klass.try(:available?, project)

        klass.new(project, current_user, params).execute(match)
      end

      private

      def fetch_klass
        match = nil
        service = COMMANDS.find do |klass|
          if klass.available?(project)
            false
          else
            match = klass.match(command)
          end
        end

        [service, match]
      end

      def help_messages
        COMMANDS.map do |klass|
          next unless klass.available?(project)

          klass.help_message
        end.compact
      end

      def command
        params[:text]
      end
    end
  end
end
