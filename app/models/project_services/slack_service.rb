class SlackService < Service
  prop_accessor :webhook, :username, :channel
  boolean_accessor :notify_only_broken_builds
  validates :webhook, presence: true, url: true, if: :activated?

  def initialize_properties
    # Custom serialized properties initialization
    self.supported_events.each { |event| self.class.prop_accessor(event_channel_name(event)) }

    if properties.nil?
      self.properties = {}
      self.notify_only_broken_builds = true
    end
  end

  def title
    'Slack'
  end

  def description
    'A team communication tool for the 21st century'
  end

  def to_param
    'slack'
  end

  def help
    'This service sends notifications to your Slack channel.<br/>
    To setup this Service you need to create a new <b>"Incoming webhook"</b> in your Slack integration panel,
    and enter the Webhook URL below.'
  end

  def fields
    default_fields =
      [
        { type: 'text', name: 'webhook',   placeholder: 'https://hooks.slack.com/services/...' },
        { type: 'text', name: 'username', placeholder: 'username' },
        { type: 'text', name: 'channel', placeholder: "#general" },
        { type: 'checkbox', name: 'notify_only_broken_builds' },
      ]

    default_fields + build_event_channels
  end

  def supported_events
    %w(push issue confidential_issue merge_request note tag_push build wiki_page)
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

    message = \
      case object_kind
      when "push", "tag_push"
        PushMessage.new(data)
      when "issue"
        IssueMessage.new(data) unless is_update?(data)
      when "merge_request"
        MergeMessage.new(data) unless is_update?(data)
      when "note"
        NoteMessage.new(data)
      when "build"
        BuildMessage.new(data) if should_build_be_notified?(data)
      when "wiki_page"
        WikiPageMessage.new(data)
      end

    opt = {}

    event_channel = get_channel_field(object_kind) || channel

    opt[:channel] = event_channel if event_channel
    opt[:username] = username if username

    if message
      notifier = Slack::Notifier.new(webhook, opt)
      notifier.ping(message.pretext, attachments: message.attachments, fallback: message.fallback)
    end
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

  private

  def get_channel_field(event)
    field_name = event_channel_name(event)
    self.public_send(field_name)
  end

  def build_event_channels
    supported_events.reduce([]) do |channels, event|
      channels << { type: 'text', name: event_channel_name(event), placeholder: "#general" }
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
end

require "slack_service/issue_message"
require "slack_service/push_message"
require "slack_service/merge_message"
require "slack_service/note_message"
require "slack_service/build_message"
require "slack_service/wiki_page_message"
