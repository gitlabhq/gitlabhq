# frozen_string_literal: true

module Integrations
  class HangoutsChat < Integration
    include Base::ChatNotification

    # Enum value of the messageReplyOption query parameter that indicates that messages should be created as replies to
    # the specified threads if possible and start new threads otherwise
    # https://developers.google.com/workspace/chat/api/reference/rest/v1/spaces.messages/create#messagereplyoption
    REPLY_MESSAGE_FALLBACK_TO_NEW_THREAD = 'REPLY_MESSAGE_FALLBACK_TO_NEW_THREAD'

    field :webhook,
      section: SECTION_TYPE_CONNECTION,
      help: -> { _('The Hangouts Chat webhook (for example, `https://chat.googleapis.com/v1/spaces...`).') },
      required: true

    field :notify_only_broken_pipelines,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION,
      description: -> { _('Send notifications for broken pipelines.') }

    field :branches_to_be_notified,
      type: :select,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('Integrations|Branches for which notifications are to be sent') },
      description: -> {
                     _('Branches to send notifications for. Valid options are `all`, `default`, `protected`, ' \
                       'and `default_and_protected`. The default value is `default`.')
                   },
      choices: -> { branch_choices }

    def self.title
      'Google Chat'
    end

    def self.description
      'Send notifications from GitLab to a space in Google Chat.'
    end

    def self.to_param
      'hangouts_chat'
    end

    def self.help
      build_help_page_url(
        'user/project/integrations/hangouts_chat.md',
        'Before enabling this integration, create a webhook for the space in Google Chat where you want to ' \
        'receive notifications from this project.',
        _('How do I set up a Google Chat webhook?')
      )
    end

    def default_channel_placeholder; end

    def self.supported_events
      %w[push issue confidential_issue merge_request note confidential_note tag_push pipeline wiki_page]
    end

    private

    def notify(message, _opts)
      url = webhook.dup

      url = Gitlab::Utils.add_url_parameters(url, { messageReplyOption: REPLY_MESSAGE_FALLBACK_TO_NEW_THREAD })

      key = parse_thread_key(message)
      payload = { text: parse_simple_text_message(message), thread: { threadKey: key }.compact }.compact_blank!

      Gitlab::HTTP.post(
        url,
        body: payload.to_json,
        headers: { 'Content-Type' => 'application/json' },
        parse: nil
      ).response
    end

    # Returns an appropriate key for threading messages in google chat
    def parse_thread_key(message)
      case message
      when Integrations::ChatMessage::NoteMessage
        message.target
      when Integrations::ChatMessage::IssueMessage
        "issue #{message.project_name}#{Issue.reference_prefix}#{message.issue_iid}"
      when Integrations::ChatMessage::MergeMessage
        "merge request #{message.project_name}#{MergeRequest.reference_prefix}#{message.merge_request_iid}"
      when Integrations::ChatMessage::PushMessage
        "push #{message.project_name}_#{message.ref}"
      when Integrations::ChatMessage::PipelineMessage
        "pipeline #{message.pipeline_id}"
      when Integrations::ChatMessage::WikiPageMessage
        "wiki_page #{message.wiki_page_url}"
      end
    end

    def parse_simple_text_message(message)
      header = message.pretext
      return header if message.attachments.empty?

      attachment = message.attachments.first
      title      = format_attachment_title(attachment)
      body       = attachment[:text]

      [header, title, body].compact.join("\n")
    end

    def format_attachment_title(attachment)
      return attachment[:title] unless attachment[:title_link]

      "<#{attachment[:title_link]}|#{attachment[:title]}>"
    end
  end
end
