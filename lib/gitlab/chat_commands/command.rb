module Gitlab
  module ChatCommands
    class Command < BaseCommand
      COMMANDS = [
        Gitlab::ChatCommands::IssueShow,
        Gitlab::ChatCommands::IssueCreate,
      ].freeze

      def execute
        klass, match = fetch_klass

        if klass
          present klass.new(project, current_user, params).execute(match)
        else
          help(help_messages)
        end
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

      def present(resource)
        Mattermost::Presenter.present(resource)
      end

      def help(messages)
        Mattermost::Presenter.help(messages, params[:command])
      end
    end
  end
end
