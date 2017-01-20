# Base class for Chat notifications services
# This class is not meant to be used directly, but only to inherit from.
class ChatNotificationService < Service
  include ChatMessage

  default_value_for :category, 'chat'

  prop_accessor :webhook, :username, :channel
  boolean_accessor :notify_only_broken_builds, :notify_only_broken_pipelines

  validates :webhook, presence: true, url: true, if: :activated?

  def initialize_properties
    # Custom serialized properties initialization
    self.supported_events.each { |event| self.class.prop_accessor(event_channel_name(event)) }

    if properties.nil?
      self.properties = {}
      self.notify_only_broken_builds = true
      self.notify_only_broken_pipelines = true
    end
  end

  def can_test?
    valid?
  end

  def supported_events
    %w[push issue confidential_issue merge_request note tag_push
       build pipeline wiki_page]
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])
    return unless webhook.present?

    object_kind = data[:object_kind]

    data = data.merge(
      project_url: project_url,
      project_name: project_name
    )

    # WebHook events often have an 'update' event that follows a 'open' or
    # 'close' action. Ignore update events for now to prevent duplicate
    # messages from arriving.

    message = get_message(object_kind, data)

    return false unless message

    channel_name = get_channel_field(object_kind).presence || channel

    opts = {}
    opts[:channel] = channel_name if channel_name
    opts[:username] = username if username

    notifier = Slack::Notifier.new(webhook, opts)
    notifier.ping(message.pretext, attachments: message.attachments, fallback: message.fallback)

    true
  end

  def event_channel_names
    supported_events.map { |event| event_channel_name(event) }
  end

  def event_field(event)
    fields.find { |field| field[:name] == event_channel_name(event) }
  end

  def global_fields
    fields.reject { |field| field[:name].end_with?('channel') }
  end

  def default_channel_placeholder
    raise NotImplementedError
  end

  private

  def get_message(object_kind, data)
    case object_kind
    when "push", "tag_push"
      ChatMessage::PushMessage.new(data)
    when "issue"
      ChatMessage::IssueMessage.new(data) unless is_update?(data)
    when "merge_request"
      ChatMessage::MergeMessage.new(data) unless is_update?(data)
    when "note"
      ChatMessage::NoteMessage.new(data)
    when "build"
      ChatMessage::BuildMessage.new(data) if should_build_be_notified?(data)
    when "pipeline"
      ChatMessage::PipelineMessage.new(data) if should_pipeline_be_notified?(data)
    when "wiki_page"
      ChatMessage::WikiPageMessage.new(data)
    end
  end

  def get_channel_field(event)
    field_name = event_channel_name(event)
    self.public_send(field_name)
  end

  def build_event_channels
    supported_events.reduce([]) do |channels, event|
      channels << { type: 'text', name: event_channel_name(event), placeholder: default_channel_placeholder }
    end
  end

  def event_channel_name(event)
    "#{event}_channel"
  end

  def project_name
    project.name_with_namespace.gsub(/\s/, '')
  end

  def project_url
    project.web_url
  end

  def is_update?(data)
    data[:object_attributes][:action] == 'update'
  end

  def should_build_be_notified?(data)
    case data[:commit][:status]
    when 'success'
      !notify_only_broken_builds?
    when 'failed'
      true
    else
      false
    end
  end

  def should_pipeline_be_notified?(data)
    case data[:object_attributes][:status]
    when 'success'
      !notify_only_broken_pipelines?
    when 'failed'
      true
    else
      false
    end
  end
end
