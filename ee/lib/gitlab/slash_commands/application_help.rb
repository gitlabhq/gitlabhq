module Gitlab
  module SlashCommands
    class ApplicationHelp < BaseCommand
      def initialize(params)
        @params = params
      end

      def execute
        Gitlab::SlashCommands::Presenters::Help.new(commands).present(trigger, params[:text])
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
