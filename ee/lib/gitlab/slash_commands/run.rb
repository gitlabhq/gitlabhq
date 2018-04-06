# frozen_string_literal: true

module Gitlab
  module SlashCommands
    # Slash command for triggering chatops jobs.
    class Run < BaseCommand
      def self.match(text)
        /\Arun\s+(?<command>\S+)(\s+(?<arguments>.+))?\z/.match(text)
      end

      def self.help_message
        'run <command> <arguments>'
      end

      def self.available?(project)
        Chat.available? && project.builds_enabled?
      end

      def self.allowed?(project, user)
        can?(user, :create_pipeline, project)
      end

      def execute(match)
        command = Chat::Command.new(
          project: project,
          chat_name: chat_name,
          name: match[:command],
          arguments: match[:arguments],
          channel: params[:channel_id],
          response_url: params[:response_url]
        )

        presenter = Gitlab::SlashCommands::Presenters::Run.new
        pipeline = command.try_create_pipeline

        if pipeline&.persisted?
          presenter.present(pipeline)
        else
          presenter.failed_to_schedule(command.name)
        end
      end
    end
  end
end
