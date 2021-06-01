# frozen_string_literal: true

module Integrations
  class MicrosoftTeams < BaseChatNotification
    def title
      'Microsoft Teams notifications'
    end

    def description
      'Send notifications about project events to Microsoft Teams.'
    end

    def self.to_param
      'microsoft_teams'
    end

    def help
      '<p>Use this service to send notifications about events in GitLab projects to your Microsoft Teams channels. <a href="https://docs.gitlab.com/ee/user/project/integrations/microsoft_teams.html">How do I configure this integration?</a></p>'
    end

    def webhook_placeholder
      'https://outlook.office.com/webhook/…'
    end

    def event_field(event)
    end

    def default_channel_placeholder
    end

    def self.supported_events
      %w[push issue confidential_issue merge_request note confidential_note tag_push
         pipeline wiki_page]
    end

    def default_fields
      [
        { type: 'text', name: 'webhook', placeholder: "#{webhook_placeholder}" },
        { type: 'checkbox', name: 'notify_only_broken_pipelines', help: 'If selected, successful pipelines do not trigger a notification event.' },
        { type: 'select', name: 'branches_to_be_notified', choices: branch_choices }
      ]
    end

    private

    def notify(message, opts)
      ::MicrosoftTeams::Notifier.new(webhook).ping(
        title: message.project_name,
        summary: message.summary,
        activity: message.activity,
        attachments: message.attachments
      )
    end

    def custom_data(data)
      super(data).merge(markdown: true)
    end
  end
end
