# frozen_string_literal: true

require 'uri'

module Integrations
  class Irker < Integration
    include ActionView::Helpers::UrlHelper

    prop_accessor :server_host, :server_port, :default_irc_uri
    prop_accessor :recipients, :channels
    boolean_accessor :colorize_messages
    validates :recipients, presence: true, if: :validate_recipients?

    before_validation :get_channels

    def title
      s_('IrkerService|irker (IRC gateway)')
    end

    def description
      s_('IrkerService|Send update messages to an irker server.')
    end

    def self.to_param
      'irker'
    end

    def self.supported_events
      %w(push)
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      IrkerWorker.perform_async(project_id, channels,
                                colorize_messages, data, settings)
    end

    def settings
      {
        server_host: server_host.presence || 'localhost',
        server_port: server_port.presence || 6659
      }
    end

    def fields
      recipients_docs_link = link_to s_('IrkerService|How to enter channels or users?'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/irker', anchor: 'enter-irker-recipients'), target: '_blank', rel: 'noopener noreferrer'
      [
        { type: 'text', name: 'server_host', placeholder: 'localhost', title: s_('IrkerService|Server host (optional)'),
          help: s_('IrkerService|irker daemon hostname (defaults to localhost).') },
        { type: 'text', name: 'server_port', placeholder: 6659, title: s_('IrkerService|Server port (optional)'),
          help: s_('IrkerService|irker daemon port (defaults to 6659).') },
        { type: 'text', name: 'default_irc_uri', title: s_('IrkerService|Default IRC URI (optional)'),
          help: s_('IrkerService|URI to add before each recipient.'),
          placeholder: 'irc://irc.network.net:6697/' },
        { type: 'textarea', name: 'recipients', title: s_('IrkerService|Recipients'),
          placeholder: 'irc[s]://irc.network.net[:port]/#channel', required: true,
          help: s_('IrkerService|Channels and users separated by whitespaces. %{recipients_docs_link}').html_safe % { recipients_docs_link: recipients_docs_link.html_safe } },
        { type: 'checkbox', name: 'colorize_messages', title: _('Colorize messages') }
      ]
    end

    def help
      docs_link = link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/irker', anchor: 'set-up-an-irker-daemon'), target: '_blank', rel: 'noopener noreferrer'
      s_('IrkerService|Send update messages to an irker server. Before you can use this, you need to set up the irker daemon. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    private

    def get_channels
      return true unless activated?
      return true if recipients.nil? || recipients.empty?

      map_recipients

      errors.add(:recipients, 'are all invalid') if channels.empty?
      true
    end

    def map_recipients
      self.channels = recipients.split(/\s+/).map do |recipient|
        format_channel(recipient)
      end
      channels.reject!(&:nil?)
    end

    def format_channel(recipient)
      uri = nil

      # Try to parse the chan as a full URI
      begin
        uri = consider_uri(URI.parse(recipient))
      rescue URI::InvalidURIError
      end

      unless uri.present? && default_irc_uri.nil?
        begin
          new_recipient = URI.join(default_irc_uri, '/', recipient).to_s
          uri = consider_uri(URI.parse(new_recipient))
        rescue StandardError
          log_error("Unable to create a valid URL", default_irc_uri: default_irc_uri, recipient: recipient)
        end
      end

      uri
    end

    def consider_uri(uri)
      return if uri.scheme.nil?

      # Authorize both irc://domain.com/#chan and irc://domain.com/chan
      if uri.is_a?(URI) && uri.scheme[/^ircs?\z/] && !uri.path.nil?
        uri.to_s
      end
    end
  end
end
