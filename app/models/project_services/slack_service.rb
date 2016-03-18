# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#  build_events          :boolean          default(FALSE), not null
#

class SlackService < Service
  prop_accessor :webhook, :username, :channel
  boolean_accessor :notify_only_broken_builds
  validates :webhook, presence: true, if: :activated?

  def initialize_properties
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
    [
      { type: 'text', name: 'webhook',
        placeholder: 'https://hooks.slack.com/services/...' },
      { type: 'text', name: 'username', placeholder: 'username' },
      { type: 'text', name: 'channel', placeholder: '#channel' },
      { type: 'checkbox', name: 'notify_only_broken_builds' },
    ]
  end

  def supported_events
    %w(push issue merge_request note tag_push build)
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
      end

    opt = {}
    opt[:channel] = channel if channel
    opt[:username] = username if username

    if message
      notifier = Slack::Notifier.new(webhook, opt)
      notifier.ping(message.pretext, attachments: message.attachments, fallback: message.fallback)
    end
  end

  private

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
