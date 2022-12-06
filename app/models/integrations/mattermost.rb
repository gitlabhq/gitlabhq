# frozen_string_literal: true

module Integrations
  class Mattermost < BaseChatNotification
    include SlackMattermostNotifier

    def title
      _('Mattermost notifications')
    end

    def description
      s_('Send notifications about project events to Mattermost channels.')
    end

    def self.to_param
      'mattermost'
    end

    def help
      docs_link = ActionController::Base.helpers.link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/mattermost'), target: '_blank', rel: 'noopener noreferrer'
      s_('Send notifications about project events to Mattermost channels. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def default_channel_placeholder
      'my-channel'
    end

    def webhook_help
      'http://mattermost.example.com/hooks/'
    end

    override :configurable_channels?
    def configurable_channels?
      true
    end
  end
end
