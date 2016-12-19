class MattermostSlashCommandsService < ChatService
  include TriggersHelper

  prop_accessor :token

  def can_test?
    false
  end

  def title
    'Mattermost Command'
  end

  def description
    "Perform common operations on GitLab in Mattermost"
  end

  def to_param
    'mattermost_slash_commands'
  end

  def fields
    [
      { type: 'text', name: 'token', placeholder: '' }
    ]
  end

  def configure(host, current_user, params)
    new_token = Mattermost::Session.new(current_user).with_session do |session|
      Mattermost::Command.create(session, params[:team_id], command)
    end

    update!(token: new_token, active: true)
  end

  def trigger(params)
    return nil unless valid_token?(params[:token])

    user = find_chat_user(params)
    unless user
      url = authorize_chat_name_url(params)
      return Mattermost::Presenter.authorize_chat_name(url)
    end

    Gitlab::ChatCommands::Command.new(project, user, params).execute
  end

  private

  def command(trigger:, url:, icon_url:)
    pretty_project_name = project.name_with_namespace

    {
      auto_complete: true,
      auto_complete_desc: "Perform common operations on: #{pretty_project_name}",
      auto_complete_hint: '[help]',
      description: "Perform common operations on: #{pretty_project_name}",
      display_name: "GitLab  / #{pretty_project_name}",
      method: 'P',
      user_name: 'GitLab',
      trigger: trigger,
      url: url,
      icon_url: icon_url
    }
  end

  def find_chat_user(params)
    ChatNames::FindUserService.new(self, params).execute
  end

  def authorize_chat_name_url(params)
    ChatNames::AuthorizeUserService.new(self, params).execute
  end
end
