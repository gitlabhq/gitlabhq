module SlashCommands
  class GlobalSlackHandler
    attr_reader :project_alias, :params

    def initialize(params)
      @project_alias, command = parse_command_text(params)
      @params = params.merge(text: command, original_command: params[:text])
    end

    def trigger
      return false unless valid_token?

      if help_command?
        return Gitlab::SlashCommands::ApplicationHelp.new(params).execute
      end

      unless integration = find_integration
        error_message = 'GitLab error: project or alias not found'
        return Gitlab::SlashCommands::Presenters::Error.new(error_message).message
      end

      service = integration.service
      project = service.project

      user = ChatNames::FindUserService.new(service, params).execute

      if user
        Gitlab::SlashCommands::Command.new(project, user, params).execute
      else
        url = ChatNames::AuthorizeUserService.new(service, params).execute
        Gitlab::SlashCommands::Presenters::Access.new(url).authorize
      end
    end

    private

    def valid_token?
      ActiveSupport::SecurityUtils.variable_size_secure_compare(
        current_application_settings.slack_app_verification_token,
        params[:token]
      )
    end

    def help_command?
      params[:original_command] == 'help'
    end

    def find_integration
      SlackIntegration.find_by(team_id: params[:team_id], alias: project_alias)
    end

    # Splits the command
    # '/gitlab help' => [nil, 'help']
    # '/gitlab group/project issue new some title' => ['group/project', 'issue new some title']
    def parse_command_text(params)
      fragments = params[:text].split(/\s/, 2)
      fragments.size == 1 ? [nil, fragments.first] : fragments
    end
  end
end
