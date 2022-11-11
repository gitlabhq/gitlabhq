# frozen_string_literal: true

module Integrations
  class HangoutsChat < BaseChatNotification
    def title
      'Google Chat'
    end

    def description
      'Send notifications from GitLab to a room in Google Chat.'
    end

    def self.to_param
      'hangouts_chat'
    end

    def help
      docs_link = ActionController::Base.helpers.link_to _('How do I set up a Google Chat webhook?'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/hangouts_chat'), target: '_blank', rel: 'noopener noreferrer'
      s_('Before enabling this integration, create a webhook for the room in Google Chat where you want to receive notifications from this project. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def default_channel_placeholder
    end

    def self.supported_events
      %w[push issue confidential_issue merge_request note confidential_note tag_push
         pipeline wiki_page]
    end

    def default_fields
      [
        { type: 'text', name: 'webhook', help: 'https://chat.googleapis.com/v1/spaces…' },
        { type: 'checkbox', name: 'notify_only_broken_pipelines' },
        {
          type: 'select',
          name: 'branches_to_be_notified',
          title: s_('Integrations|Branches for which notifications are to be sent'),
          choices: self.class.branch_choices
        }
      ]
    end

    private

    def notify(message, opts)
      url = webhook.dup

      key = parse_thread_key(message)
      url = Gitlab::Utils.add_url_parameters(url, { threadKey: key }) if key

      simple_text = parse_simple_text_message(message)
      ::HangoutsChat::Sender.new(url).simple(simple_text)
    end

    # Returns an appropriate key for threading messages in google chat
    def parse_thread_key(message)
      case message
      when Integrations::ChatMessage::NoteMessage
        message.target
      when Integrations::ChatMessage::IssueMessage
        "issue #{Issue.reference_prefix}#{message.issue_iid}"
      when Integrations::ChatMessage::MergeMessage
        "merge request #{MergeRequest.reference_prefix}#{message.merge_request_iid}"
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
