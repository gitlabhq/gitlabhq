# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class GlobalSlackHandler
      attr_reader :project_alias, :params

      def initialize(params)
        @project_alias, command = parse_command_text(params)
        @params = params.merge(text: command, original_command: params[:text])
      end

      def trigger
        return false unless valid_token?
        return Gitlab::SlashCommands::ApplicationHelp.new(nil, params).execute if help_command?

        unless integration = find_slack_integration
          error_message = 'GitLab error: project or alias not found'
          return Gitlab::SlashCommands::Presenters::Error.new(error_message).message
        end

        chat_user = ChatNames::FindUserService.new(params[:team_id], params[:user_id]).execute

        if chat_user&.user
          Gitlab::SlashCommands::Command.new(integration.project, chat_user, params).execute
        else
          url = ChatNames::AuthorizeUserService.new(params).execute
          Gitlab::SlashCommands::Presenters::Access.new(url).authorize
        end
      end

      private

      def valid_token?
        ActiveSupport::SecurityUtils.secure_compare(
          Gitlab::CurrentSettings.current_application_settings
            .slack_app_verification_token,
          params[:token]
        )
      end

      def help_command?
        params[:original_command] == 'help'
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def find_slack_integration
        find_params = { team_id: params[:team_id], alias: project_alias }.compact
        slack_app = SlackIntegration.find_by(find_params)

        return unless slack_app

        integration = slack_app.integration
        integration if integration.project_level?
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Splits the command
      # '/gitlab help' => [nil, 'help']
      # '/gitlab group/project issue new some title' => ['group/project', 'issue new some title']
      def parse_command_text(params)
        if params[:text] == 'incident declare'
          [nil, params[:text]]
        else
          fragments = params[:text].split(/\s/, 2)
          fragments.size == 1 ? [nil, fragments.first] : fragments
        end
      end
    end
  end
end

Gitlab::SlashCommands::GlobalSlackHandler.prepend_mod
