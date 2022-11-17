# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class ApplicationHelp < BaseCommand
      def execute
        Gitlab::SlashCommands::Presenters::Help
          .new(project, commands, params)
          .present(trigger, params[:text])
      end

      private

      def trigger
        "#{params[:command]} [project name or alias]"
      end

      def commands
        Gitlab::SlashCommands::Command.new(
          project,
          chat_name,
          params
        ).commands
      end
    end
  end
end
