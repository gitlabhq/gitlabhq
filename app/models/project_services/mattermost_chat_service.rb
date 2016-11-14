# Base class for Chat services
class MattermostChatService < ChatService
  def title
    'Mattermost'
  end

  def description
    'Mattermost is an open source, self-hosted Slack-alternative'
  end

  def to_param
    'mattermost'
  end

  def help
    'This service allows you to use slash commands with your Mattermost installation.<br/>
    To setup this Service you need to create a new <b>"Slash commands"</b> in your Mattermost integration panel,
    and enter the token below.'
  end

  def fields
    [
      { type: 'text', name: 'token', placeholder: 'https://hooks.slack.com/services/...' }
    ]
  end

  def trigger(params)
    user = ChatNames::FindUserService.new(chat_names, params).execute
    return authorize_chat_name(params) unless user

    Mattermost::CommandService.new(project, user, params).execute
  end

  private

  def authorize_chat_name(params)
    url = ChatNames::RequestService.new(service, params).execute

    {
      response_type: :ephemeral,
      message: "You are not authorized. Click this [link](#{url}) to authorize."
    }
  end
end
