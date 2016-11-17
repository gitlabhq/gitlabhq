module Gitlab
  module ChatCommands
    class Command < BaseCommand
      COMMANDS = [
        Gitlab::ChatCommands::IssueShow,
        Gitlab::ChatCommands::IssueCreate,
      ].freeze

      def execute
        command, match = match_command

        if command
          if command.allowed?(project, current_user)
            present command.new(project, current_user, params).execute(match)
          else
            access_denied
          end
        else
          help(help_messages)
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

      def help_messages
        available_commands.map(&:help_message)
      end

      def available_commands
        COMMANDS.select do |klass|
          klass.available?(project)
        end
      end

      def command
        params[:text]
      end

      def help(messages)
        Mattermost::Presenter.help(messages, params[:command])
      end

      def access_denied
        Mattermost::Presenter.access_denied
      end

      def present(resource)
        Mattermost::Presenter.present(resource)
      end
    end
  end
end
