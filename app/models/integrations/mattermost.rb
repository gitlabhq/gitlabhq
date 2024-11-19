# frozen_string_literal: true

module Integrations
  class Mattermost < Integration
    include Base::ChatNotification
    include SlackMattermostNotifier
    include SlackMattermostFields
    include HasAvatar

    def self.title
      _('Mattermost notifications')
    end

    def self.description
      s_('Send notifications about project events to Mattermost channels.')
    end

    def self.to_param
      'mattermost'
    end

    def self.help
      build_help_page_url(
        'user/project/integrations/mattermost.md', s_("Send notifications about project events to Mattermost channels.")
      )
    end

    def default_channel_placeholder
      'my-channel'
    end

    def self.webhook_help
      'http://mattermost.example.com/hooks/...'
    end

    override :configurable_channels?
    def configurable_channels?
      true
    end
  end
end
