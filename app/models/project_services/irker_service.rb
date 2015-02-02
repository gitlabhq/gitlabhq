# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

require 'uri'
require 'socket'

# See the note in the worker for extra configuration

class IrkerService < Service
  prop_accessor :colorize_messages, :recipients, :channels
  validates :recipients, presence: true, if: :activated?
  validate :check_recipients_count, if: :activated?
  validate :check_irker

  before_validation :get_channels

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
    '"?key=secretpassword" to the URI. '
    
    begin 
      default_irc = Gitlab.config.irker.default_irc_uri
    rescue Settingslogic::MissingSetting
      # Display nothing more
    else
      msg += 'Note that a default IRC URI is provided by this service\'s '\
      "administrator: #{default_irc}. You can thus just give a channel name."
    end
    msg
  end

  def to_param
    'irker'
  end

  def execute(push_data)
    IrkerWorker.perform_async(project_id, channels,
                              colorize_messages, push_data)
  end

  def fields
    [
      { type: 'textarea', name: 'recipients',
          placeholder: 'Recipients/channels separated by whitespaces' },
      { type: 'checkbox', name: 'colorize_messages' },
    ]
  end

  def check_recipients_count
    return false if recipients.nil? || recipients.empty?

    begin
      max_chans = Gitlab.config.irker.max_channels
    rescue Settingslogic::MissingSetting
      max_chans = 3
    end

    if recipients.split(/\s+/).count > max_chans
      errors.add(:recipients, "are limited to #{max_chans}")
    end
  end

  def check_irker
    begin
      host = Gitlab.config.irker.server_ip
      port = Gitlab.config.irker.server_port
    rescue Settingslogic::MissingSetting
      host = 'localhost'
      port = 6659
    end
    begin
      TCPSocket.new(host, port).close
    rescue Errno::ECONNREFUSED => e
      logger.fatal "Can't connect to Irker daemon: #{e}"
      msg  = '- Can\'t connect to the Irker daemon, '
      msg += 'please contact the server administrator if the problem persists.'
      errors.add(:active, msg)
    end
  end

  def get_channels
    return true unless :activated?

    begin
      default_irc = Gitlab.config.irker.default_irc_uri
    rescue Settingslogic::MissingSetting
      default_irc = nil
    else
      default_irc += '/' unless default_irc[-1] == '/'
    end

    self.channels = recipients.split(/\s+/).map do |c|
      cnt = 0
      url = nil

      # Now try to parse the chan as a full URI
      begin
        uri = URI.parse(c)
        raise URI::InvalidURIError if uri.scheme.nil? && cnt == 0
      rescue URI::InvalidURIError
        unless default_irc.nil?
          cnt += 1
          c = "#{default_irc}#{c}"
          retry if cnt == 1
        end
      else
        # Authorize both irc://domain.com/#chan and irc://domain.com/chan
        if uri.is_a?(URI) && uri.scheme[/^ircs?$/] && not uri.path.nil?
          if uri.fragment.nil?
            # Do not authorize irc://domain.com/
            url = uri.to_s if uri.path.length > 1
          else
            # Authorize irc://domain.com/smthg#chan
            # The irker daemon will deal with it by concatenating smthg and
            # chan, thus sending messages on #smthgchan
            url = uri.to_s
          end
        end
      end
      url
    end
    self.channels.reject! { |c| c.nil? }

    errors.add(:recipients, 'are all invalid') if channels.empty?
    logger.debug "IrkerService: rcpts = #{recipients}; chans = #{channels}"
    true
  end
end
