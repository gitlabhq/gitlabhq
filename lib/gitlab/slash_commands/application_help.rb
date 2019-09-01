# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class ApplicationHelp < BaseCommand
      def initialize(project, params)
        @project = project
        @params = params
      end

      def execute
        Gitlab::SlashCommands::Presenters::Help
          .new(project, commands)
          .present(trigger, params[:text])
      end

      private

      def trigger
        "#{params[:command]} [project name or alias]"
      end

      def commands
        Gitlab::SlashCommands::Command.commands
      end
    end
  end
end
