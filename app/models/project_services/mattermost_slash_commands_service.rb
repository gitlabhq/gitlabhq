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

  def configure!(current_user, params)
    token = Mattermost::Session.new(current_user).with_session do |session|
      Mattermost::Command.create(session, command(params))
    end

    update!(active: true, token: token)
  end

  def list_teams(user)
    Mattermost::Session.new(user).with_session do |session|
      Mattermost::Team.all(session)
    end
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

  def command(params)
    pretty_project_name = project.name_with_namespace

    params.merge(
      auto_complete: true,
      auto_complete_desc: "Perform common operations on: #{pretty_project_name}",
      auto_complete_hint: '[help]',
      description: "Perform common operations on: #{pretty_project_name}",
      display_name: "GitLab  / #{pretty_project_name}",
      method: 'P',
      user_name: 'GitLab')
  end

  def find_chat_user(params)
    ChatNames::FindUserService.new(self, params).execute
  end

  def authorize_chat_name_url(params)
    ChatNames::AuthorizeUserService.new(self, params).execute
  end
end
