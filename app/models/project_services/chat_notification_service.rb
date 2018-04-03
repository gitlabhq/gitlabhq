# Base class for Chat notifications services
# This class is not meant to be used directly, but only to inherit from.
class ChatNotificationService < Service
  include ChatMessage

  default_value_for :category, 'chat'

  prop_accessor :webhook, :username, :channel
  boolean_accessor :notify_only_broken_pipelines, :notify_only_default_branch

  validates :webhook, presence: true, url: true, if: :activated?

  def initialize_properties
    # Custom serialized properties initialization
    self.supported_events.each { |event| self.class.prop_accessor(event_channel_name(event)) }

    if properties.nil?
      self.properties = {}
      self.notify_only_broken_pipelines = true
      self.notify_only_default_branch = true
    end
  end

  def confidential_issue_channel
    properties['confidential_issue_channel'].presence || properties['issue_channel']
  end

  def confidential_note_channel
    properties['confidential_note_channel'].presence || properties['note_channel']
  end

  def self.supported_events
    %w[push issue confidential_issue merge_request note confidential_note tag_push
       pipeline wiki_page]
  end

  def fields
    default_fields + build_event_channels
  end

  def default_fields
    [
      { type: 'text', name: 'webhook', placeholder: "e.g. #{webhook_placeholder}", required: true },
      { type: 'text', name: 'username', placeholder: 'e.g. GitLab' },
      { type: 'checkbox', name: 'notify_only_broken_pipelines' },
      { type: 'checkbox', name: 'notify_only_default_branch' }
    ]
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])
    return unless webhook.present?

    object_kind = data[:object_kind]

    data = custom_data(data)

    # WebHook events often have an 'update' event that follows a 'open' or
    # 'close' action. Ignore update events for now to prevent duplicate
    # messages from arriving.

    message = get_message(object_kind, data)

    return false unless message

    event_type = data[:event_type] || object_kind

    channel_name = get_channel_field(event_type).presence || channel

    opts = {}
    opts[:channel] = channel_name if channel_name
    opts[:username] = username if username

    return false unless notify(message, opts)

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

  def notify(message, opts)
    Slack::Notifier.new(webhook, opts).ping(
      message.pretext,
      attachments: message.attachments,
      fallback: message.fallback
    )
  end

  def custom_data(data)
    data.merge(project_url: project_url, project_name: project_name)
  end

  def get_message(object_kind, data)
    case object_kind
    when "push", "tag_push"
      ChatMessage::PushMessage.new(data)
    when "issue"
      ChatMessage::IssueMessage.new(data) unless update?(data)
    when "merge_request"
      ChatMessage::MergeMessage.new(data) unless update?(data)
    when "note"
      ChatMessage::NoteMessage.new(data)
    when "pipeline"
      ChatMessage::PipelineMessage.new(data) if should_pipeline_be_notified?(data)
    when "wiki_page"
      ChatMessage::WikiPageMessage.new(data)
    end
  end

  def get_channel_field(event)
    field_name = event_channel_name(event)
    self.public_send(field_name) # rubocop:disable GitlabSecurity/PublicSend
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

  def update?(data)
    data[:object_attributes][:action] == 'update'
  end

  def should_pipeline_be_notified?(data)
    notify_for_ref?(data) && notify_for_pipeline?(data)
  end

  def notify_for_ref?(data)
    return true if data[:object_attributes][:tag]
    return true unless notify_only_default_branch?

    data[:object_attributes][:ref] == project.default_branch
  end

  def notify_for_pipeline?(data)
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
