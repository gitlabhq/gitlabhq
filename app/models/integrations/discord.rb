# frozen_string_literal: true

require "discordrb/webhooks"

module Integrations
  class Discord < BaseChatNotification
    ATTACHMENT_REGEX = /: (?<entry>.*?)\n - (?<name>.*)\n*/.freeze

    undef :notify_only_broken_pipelines

    field :webhook,
      section: SECTION_TYPE_CONNECTION,
      help: 'e.g. https://discord.com/api/webhooks/…',
      required: true

    field :notify_only_broken_pipelines,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION

    field :branches_to_be_notified,
      type: :select,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('Integrations|Branches for which notifications are to be sent') },
      choices: -> { branch_choices }

    def title
      s_("DiscordService|Discord Notifications")
    end

    def description
      s_("DiscordService|Send notifications about project events to a Discord channel.")
    end

    def self.to_param
      "discord"
    end

    def help
      docs_link = ActionController::Base.helpers.link_to _('How do I set up this service?'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/discord_notifications'), target: '_blank', rel: 'noopener noreferrer'
      s_('Send notifications about project events to a Discord channel. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def default_channel_placeholder
      s_('DiscordService|Override the default webhook (e.g. https://discord.com/api/webhooks/…)')
    end

    def self.supported_events
      %w[push issue confidential_issue merge_request note confidential_note tag_push pipeline wiki_page]
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

    def configurable_channels?
      true
    end

    def channel_limit_per_event
      1
    end

    def mask_configurable_channels?
      true
    end

    private

    def notify(message, opts)
      webhook_url = opts[:channel]&.first || webhook
      client = Discordrb::Webhooks::Client.new(url: webhook_url)

      client.execute do |builder|
        builder.add_embed do |embed|
          embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: message.user_name, icon_url: message.user_avatar)
          embed.description = (message.pretext + "\n" + Array.wrap(message.attachments).join("\n")).gsub(ATTACHMENT_REGEX, " \\k<entry> - \\k<name>\n")
          embed.colour = 16543014 # The hex "fc6d26" as an Integer
          embed.timestamp = Time.now.utc
        end
      end
    rescue RestClient::Exception => e
      log_error(e.message)
      false
    end

    def custom_data(data)
      super(data).merge(markdown: true)
    end
  end
end
