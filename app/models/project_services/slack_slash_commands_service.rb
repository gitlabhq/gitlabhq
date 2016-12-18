class SlackSlashCommandsService < ChatSlashCommandsService
  include TriggersHelper

  def title
    'Slack Command'
  end

  def description
    "Perform common operations on GitLab in Slack"
  end

  def to_param
    'slack_slash_commands'
  end

  def trigger(params)
    result = super

    # Format messages to be Slack-compatible
    if result && result[:text]
      result[:text] = Slack::Notifier::LinkFormatter.format(result[:text])
    end

    result
  end
end
