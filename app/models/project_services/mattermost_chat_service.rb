class MattermostChatService < ChatService
  include TriggersHelper

  prop_accessor :token

  def can_test?
    false
  end

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
    "This service allows you to use slash commands with your Mattermost installation.<br/>
    To setup this Service you need to create a new <b>Slash commands</b> in your Mattermost integration panel.<br/>
    <br/>
    Create integration with URL #{service_trigger_url(self)} and enter the token below."
  end

  def fields
    [
      { type: 'text', name: 'token', placeholder: '' }
    ]
  end

  def trigger(params)
    return nil unless valid_token?(params[:token])

    user = find_chat_user(params)
    return authorize_chat_name(params) unless user

    Mattermost::CommandService.new(project, user, params.slice(:command, :text)).
      execute
  end

  private

  def find_chat_user(params)
    params = params.slice(:team_id, :user_id)
    ChatNames::FindUserService.
      new(chat_names, params).
      execute
  end

  def authorize_chat_name(params)
    params = params.slice(:team_id, :team_domain, :user_id, :user_name)
    url = ChatNames::AuthorizeUserService.new(self, params).execute

    {
      response_type: :ephemeral,
      message: "You are not authorized. Click this [link](#{url}) to authorize."
    }
  end
end
