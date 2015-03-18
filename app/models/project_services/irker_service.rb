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
#

require 'uri'

class IrkerService < Service
  prop_accessor :colorize_messages, :recipients, :channels
  validates :recipients, presence: true, if: :activated?
  validate :check_recipients_count, if: :activated?

  before_validation :get_channels
  after_initialize :initialize_settings

  # Writer for RSpec tests
  attr_writer :settings

  def initialize_settings
    # See the documentation (doc/project_services/irker.md) for possible values
    # here
    @settings ||= {
      server_ip: 'localhost',
      server_port: 6659,
      max_channels: 3,
      default_irc_uri: nil
    }
  end

  def title
    'Irker (IRC gateway)'
  end

  def description
    'Send IRC messages, on update, to a list of recipients through an Irker '\
    'gateway.'
  end

  def help
    msg = 'Recipients have to be specified with a full URI: '\
    'irc[s]://irc.network.net[:port]/#channel. Special cases: if you want '\
    'the channel to be a nickname instead, append ",isnick" to the channel '\
    'name; if the channel is protected by a secret password, append '\
    '"?key=secretpassword" to the URI.'

    unless @settings[:default_irc].nil?
      msg += ' Note that a default IRC URI is provided by this service\'s '\
      "administrator: #{default_irc}. You can thus just give a channel name."
    end
    msg
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
                              colorize_messages, data, @settings)
  end

  def fields
    [
      { type: 'textarea', name: 'recipients',
        placeholder: 'Recipients/channels separated by whitespaces' },
      { type: 'checkbox', name: 'colorize_messages' },
    ]
  end

  private

  def check_recipients_count
    return true if recipients.nil? || recipients.empty?

    if recipients.split(/\s+/).count > max_chans
      errors.add(:recipients, "are limited to #{max_chans}")
    end
  end

  def max_chans
    @settings[:max_channels]
  end

  def get_channels
    return true unless :activated?
    return true if recipients.nil? || recipients.empty?

    map_recipients

    errors.add(:recipients, 'are all invalid') if channels.empty?
    true
  end

  def map_recipients
    self.channels = recipients.split(/\s+/).map do |recipient|
      format_channel default_irc_uri, recipient
    end
    channels.reject! &:nil?
  end

  def default_irc_uri
    default_irc = @settings[:default_irc_uri]
    if !(default_irc.nil? || default_irc[-1] == '/')
      default_irc += '/'
    end
    default_irc
  end

  def format_channel(default_irc, recipient)
    cnt = 0
    url = nil

    # Try to parse the chan as a full URI
    begin
      uri = URI.parse(recipient)
      raise URI::InvalidURIError if uri.scheme.nil? && cnt == 0
    rescue URI::InvalidURIError
      unless default_irc.nil?
        cnt += 1
        recipient = "#{default_irc}#{recipient}"
        retry if cnt == 1
      end
    else
      url = consider_uri uri
    end
    url
  end

  def consider_uri(uri)
    # Authorize both irc://domain.com/#chan and irc://domain.com/chan
    if uri.is_a?(URI) && uri.scheme[/^ircs?$/] && !uri.path.nil?
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
