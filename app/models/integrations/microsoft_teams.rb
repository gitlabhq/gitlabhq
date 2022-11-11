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
      '<p>Use this service to send notifications about events in GitLab projects to your Microsoft Teams channels. <a href="https://docs.gitlab.com/ee/user/project/integrations/microsoft_teams.html" target="_blank" rel="noopener noreferrer">How do I configure this integration?</a></p>'
    end

    def default_channel_placeholder
    end

    def self.supported_events
      %w[push issue confidential_issue merge_request note confidential_note tag_push
         pipeline wiki_page]
    end

    def default_fields
      [
        { type: 'text', section: SECTION_TYPE_CONNECTION, name: 'webhook', help: 'https://outlook.office.com/webhook/…', required: true },
        {
          type: 'checkbox',
          section: SECTION_TYPE_CONFIGURATION,
          name: 'notify_only_broken_pipelines',
          help: 'If selected, successful pipelines do not trigger a notification event.'
        },
        {
          type: 'select',
          section: SECTION_TYPE_CONFIGURATION,
          name: 'branches_to_be_notified',
          title: s_('Integrations|Branches for which notifications are to be sent'),
          choices: self.class.branch_choices
        }
      ]
    end

    def sections
      [
        {
          type: SECTION_TYPE_CONNECTION,
          title: s_('Integrations|Connection details'),
          description: help
        },
        {
          type: SECTION_TYPE_TRIGGER,
          title: s_('Integrations|Trigger'),
          description: s_('Integrations|An event will be triggered when one of the following items happen.')
        },
        {
          type: SECTION_TYPE_CONFIGURATION,
          title: s_('Integrations|Notification settings'),
          description: s_('Integrations|Configure the scope of notifications.')
        }
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
