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
    user = ChatNames::FindUserService.new(chat_names, params).execute
    return Mattermost::Presenter.authorize_chat_name(params) unless user

    Mattermost::CommandService.new(project, user, params.slice(:command, :text)).
      execute
  end
end
