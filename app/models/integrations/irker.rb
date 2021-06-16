# frozen_string_literal: true

require 'uri'

module Integrations
  class Irker < Integration
    prop_accessor :server_host, :server_port, :default_irc_uri
    prop_accessor :recipients, :channels
    boolean_accessor :colorize_messages
    validates :recipients, presence: true, if: :validate_recipients?

    before_validation :get_channels

    def title
      'Irker (IRC gateway)'
    end

    def description
      'Send IRC messages.'
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
      [
        { type: 'text', name: 'server_host', placeholder: 'localhost',
          help: 'Irker daemon hostname (defaults to localhost)' },
        { type: 'text', name: 'server_port', placeholder: 6659,
          help: 'Irker daemon port (defaults to 6659)' },
        { type: 'text', name: 'default_irc_uri', title: 'Default IRC URI',
          help: 'A default IRC URI to prepend before each recipient (optional)',
          placeholder: 'irc://irc.network.net:6697/' },
        { type: 'textarea', name: 'recipients',
          placeholder: 'Recipients/channels separated by whitespaces', required: true,
          help: 'Recipients have to be specified with a full URI: '\
          'irc[s]://irc.network.net[:port]/#channel. Special cases: if '\
          'you want the channel to be a nickname instead, append ",isnick" to ' \
          'the channel name; if the channel is protected by a secret password, ' \
          ' append "?key=secretpassword" to the URI (Note that due to a bug, if you ' \
          ' want to use a password, you have to omit the "#" on the channel). If you ' \
          ' specify a default IRC URI to prepend before each recipient, you can just ' \
          ' give a channel name.' },
        { type: 'checkbox', name: 'colorize_messages' }
      ]
    end

    def help
      ' NOTE: Irker does NOT have built-in authentication, which makes it' \
      ' vulnerable to spamming IRC channels if it is hosted outside of a ' \
      ' firewall. Please make sure you run the daemon within a secured network ' \
      ' to prevent abuse. For more details, read: http://www.catb.org/~esr/irker/security.html.'
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
