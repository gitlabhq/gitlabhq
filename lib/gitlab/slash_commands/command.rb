# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class Command < BaseCommand
      def self.commands
        commands = [
          Gitlab::SlashCommands::IssueShow,
          Gitlab::SlashCommands::IssueNew,
          Gitlab::SlashCommands::IssueSearch,
          Gitlab::SlashCommands::IssueMove,
          Gitlab::SlashCommands::IssueClose,
          Gitlab::SlashCommands::IssueComment,
          Gitlab::SlashCommands::Deploy,
          Gitlab::SlashCommands::Run
        ]

        if Feature.enabled?(:incident_declare_slash_command)
          commands << Gitlab::SlashCommands::IncidentManagement::IncidentNew
        end

        commands
      end

      def execute
        command, match = match_command

        if command
          if command.allowed?(project, current_user)
            command.new(project, chat_name, params).execute(match)
          else
            Gitlab::SlashCommands::Presenters::Access.new.access_denied(project)
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
        self.class.commands.keep_if do |klass|
          klass.available?(project)
        end
      end
    end
  end
end
