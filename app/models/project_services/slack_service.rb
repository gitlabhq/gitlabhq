# frozen_string_literal: true

class SlackService < ChatNotificationService
  include SlackMattermost::Notifier

  prop_accessor EVENT_CHANNEL['alert']

  def title
    'Slack notifications'
  end

  def description
    'Receive event notifications in Slack'
  end

  def self.to_param
    'slack'
  end

  def default_channel_placeholder
    _('Slack channels (e.g. general, development)')
  end

  def webhook_placeholder
    'https://hooks.slack.com/services/…'
  end

  def supported_events
    additional = []
    additional << 'alert'

    super + additional
  end

  def get_message(object_kind, data)
    return ChatMessage::AlertMessage.new(data) if object_kind == 'alert'

    super
  end
end
