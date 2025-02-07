# frozen_string_literal: true

require 'uri'

module Integrations
  module Base
    module Irker
      extend ActiveSupport::Concern

      class_methods do
        def title
          s_('IrkerService|irker (IRC gateway)')
        end

        def description
          s_('IrkerService|Send update messages to an irker server.')
        end

        def help
          build_help_page_url(
            'user/project/integrations/irker.md',
            s_('IrkerService|Send update messages to an irker server. Before you can use this, ' \
              'you need to set up the irker daemon.'),
            { anchor: 'set-up-an-irker-daemon' }
          )
        end

        def to_param
          'irker'
        end

        def supported_events
          %w[push]
        end
      end

      included do
        validates :recipients, presence: true, if: :validate_recipients?
        before_validation :get_channels

        field :server_host,
          placeholder: 'localhost',
          title: -> { s_('IrkerService|Server host (optional)') },
          help: -> { s_('IrkerService|irker daemon hostname. The default value is `localhost`.') }

        field :server_port,
          placeholder: 6659,
          type: :number,
          title: -> { s_('IrkerService|Server port (optional)') },
          help: -> { s_('IrkerService|irker daemon port. The default value is `6659`.') }

        field :default_irc_uri,
          title: -> { s_('IrkerService|Default IRC URI (optional)') },
          help: -> { s_('IrkerService|URI to add before each recipient.') },
          placeholder: 'irc://irc.network.net:6697/',
          description: -> do
            s_('IrkerService|URI to add before each recipient. The default value is `irc://irc.network.net:6697/`.')
          end

        field :recipients,
          type: :textarea,
          title: -> { s_('IrkerService|Recipients') },
          placeholder: 'irc[s]://irc.network.net[:port]/#channel',
          description: -> { s_('IrkerService|Comma-separated list of channels or email addresses.') },
          required: true,
          help: -> do
            recipients_docs_link = ActionController::Base.helpers.link_to(
              s_('IrkerService|How to enter channels or users?'),
              Rails.application.routes.url_helpers.help_page_url(
                'user/project/integrations/irker.md',
                anchor: 'enter-irker-recipients'
              ),
              target: '_blank', rel: 'noopener noreferrer'
            )

            format(
              ERB::Util.html_escape(
                s_('IrkerService|Channels and users separated by whitespaces. %{recipients_docs_link}')
              ),
              recipients_docs_link: recipients_docs_link.html_safe # rubocop:disable Rails/OutputSafety -- It is fine to call html_safe here
            )
          end

        field :colorize_messages,
          type: :checkbox,
          title: -> { _('Colorize messages') },
          description: -> { _('Colorize messages') }

        # NOTE: This field is only used internally to store the parsed
        # channels from the `recipients` field, it should not be exposed
        # in the UI or API.
        prop_accessor :channels
      end

      def execute(data)
        return unless supported_events.include?(data[:object_kind])

        serialized_data = data.deep_stringify_keys

        Integrations::IrkerWorker.perform_async(
          project_id, channels,
          colorize_messages, serialized_data, settings
        )
      end

      def settings
        {
          'server_host' => server_host.presence || 'localhost',
          'server_port' => server_port.presence || 6659
        }
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
        return unless uri.is_a?(URI) && uri.scheme.present?
        # Authorize both irc://domain.com/#chan and irc://domain.com/chan
        return unless uri.scheme =~ /\Aircs?\z/ && !uri.path.nil?

        uri.to_s
      end
    end
  end
end
