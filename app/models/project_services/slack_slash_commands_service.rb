class SlackSlashCommandsService < ChatSlashCommandsService
  include TriggersHelper

  def title
    'Slack Slash Command'
  end

  def description
    "Perform common operations on GitLab in Slack"
  end

  def to_param
    'slack_slash_commands'
  end

  def presenter
    Gitlab::ChatCommands::Presenters::Mattermost.new
  end
end
