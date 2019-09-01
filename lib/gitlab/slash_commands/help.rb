# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class Help < BaseCommand
      # This class has to be used last, as it always matches. It has to match
      # because other commands were not triggered and we want to show the help
      # command
      def self.match(_text)
        true
      end

      def self.help_message
        'help'
      end

      def self.allowed?(_project, _user)
        true
      end

      def execute(commands, text)
        Gitlab::SlashCommands::Presenters::Help
          .new(project, commands)
          .present(trigger, text)
      end

      def trigger
        params[:command]
      end
    end
  end
end
