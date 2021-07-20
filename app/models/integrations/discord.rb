# frozen_string_literal: true

require "discordrb/webhooks"

module Integrations
  class Discord < BaseChatNotification
    include ActionView::Helpers::UrlHelper

    ATTACHMENT_REGEX = /: (?<entry>.*?)\n - (?<name>.*)\n*/.freeze

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
      docs_link = link_to _('How do I set up this service?'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/discord_notifications'), target: '_blank', rel: 'noopener noreferrer'
      s_('Send notifications about project events to a Discord channel. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def event_field(event)
      # No-op.
    end

    def default_channel_placeholder
      # No-op.
    end

    def self.supported_events
      %w[push issue confidential_issue merge_request note confidential_note tag_push pipeline wiki_page]
    end

    def default_fields
      [
        { type: "text", name: "webhook", placeholder: "https://discordapp.com/api/webhooks/…", help: "URL to the webhook for the Discord channel." },
        { type: "checkbox", name: "notify_only_broken_pipelines" },
        { type: 'select', name: 'branches_to_be_notified', choices: branch_choices }
      ]
    end

    private

    def notify(message, opts)
      client = Discordrb::Webhooks::Client.new(url: webhook)

      client.execute do |builder|
        builder.add_embed do |embed|
          embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: message.user_name, icon_url: message.user_avatar)
          embed.description = (message.pretext + "\n" + Array.wrap(message.attachments).join("\n")).gsub(ATTACHMENT_REGEX, " \\k<entry> - \\k<name>\n")
          embed.colour = 16543014 # The hex "fc6d26" as an Integer
          embed.timestamp = Time.now.utc
        end
      end
    rescue RestClient::Exception => error
      log_error(error.message)
      false
    end

    def custom_data(data)
      super(data).merge(markdown: true)
    end
  end
end
