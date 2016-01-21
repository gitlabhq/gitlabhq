# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#  build_events          :boolean          default(FALSE), not null
#

require 'uri'

class IrkerService < Service
  prop_accessor :server_host, :server_port, :default_irc_uri
  prop_accessor :colorize_messages, :recipients, :channels
  validates :recipients, presence: true, if: :activated?

  before_validation :get_channels

  def title
    'Irker (IRC gateway)'
  end

  def description
    'Send IRC messages, on update, to a list of recipients through an Irker '\
    'gateway.'
  end

  def to_param
    'irker'
  end

  def supported_events
    %w(push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    IrkerWorker.perform_async(project_id, channels,
                              colorize_messages, data, settings)
  end

  def settings
    { server_host: server_host.present? ? server_host : 'localhost',
      server_port: server_port.present? ? server_port : 6659
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
        placeholder: 'Recipients/channels separated by whitespaces',
        help: 'Recipients have to be specified with a full URI: '\
        'irc[s]://irc.network.net[:port]/#channel. Special cases: if '\
        'you want the channel to be a nickname instead, append ",isnick" to ' \
        'the channel name; if the channel is protected by a secret password, ' \
        ' append "?key=secretpassword" to the URI (Note that due to a bug, if you ' \
        ' want to use a password, you have to omit the "#" on the channel). If you ' \
        ' specify a default IRC URI to prepend before each recipient, you can just ' \
        ' give a channel name.'  },
      { type: 'checkbox', name: 'colorize_messages' },
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
    return true unless :activated?
    return true if recipients.nil? || recipients.empty?

    map_recipients

    errors.add(:recipients, 'are all invalid') if channels.empty?
    true
  end

  def map_recipients
    self.channels = recipients.split(/\s+/).map do |recipient|
      format_channel(recipient)
    end
    channels.reject! &:nil?
  end

  def format_channel(recipient)
    uri = nil

    # Try to parse the chan as a full URI
    begin
      uri = consider_uri(URI.parse(recipient))
    rescue URI::InvalidURIError
    end

    unless uri.present? and default_irc_uri.nil?
      begin
        new_recipient = URI.join(default_irc_uri, '/', recipient).to_s
        uri = consider_uri(URI.parse(new_recipient))
      rescue
        Rails.logger.error("Unable to create a valid URL from #{default_irc_uri} and #{recipient}")
      end
    end

    uri
  end

  def consider_uri(uri)
    return nil if uri.scheme.nil?

    # Authorize both irc://domain.com/#chan and irc://domain.com/chan
    if uri.is_a?(URI) && uri.scheme[/^ircs?\z/] && !uri.path.nil?
      # Do not authorize irc://domain.com/
      if uri.fragment.nil? && uri.path.length > 1
        uri.to_s
      else
        # Authorize irc://domain.com/smthg#chan
        # The irker daemon will deal with it by concatenating smthg and
        # chan, thus sending messages on #smthgchan
        uri.to_s
      end
    end
  end
end
