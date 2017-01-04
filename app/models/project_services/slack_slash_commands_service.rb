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
    # Format messages to be Slack-compatible
    super.tap do |result|
      result[:text] = format(result[:text]) if result.is_a?(Hash)
    end
  end

  private

  def format(text)
    Slack::Notifier::LinkFormatter.format(text) if text
  end
end
