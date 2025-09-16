# frozen_string_literal: true

require 'mail/smtp_pool'

# Based on https://github.com/mikel/mail/blob/2.8.1/spec/spec_helper.rb#L73-L155
class Net::SMTP
  class << self
    alias unstubbed_new new
  end

  def self.new(*args)
    MockSMTP.new
  end
end

# Original mockup from ActionMailer
class MockSMTP
  attr_accessor :open_timeout, :read_timeout

  def self.reset
    test = Net::SMTP.unstubbed_new('example.com')
    @@tls = test.tls?
    @@starttls = test.starttls?

    @@deliveries = []
    @started = false
  end

  reset

  def self.deliveries
    @@deliveries
  end

  def self.tls
    @@tls
  end

  def self.starttls
    @@starttls
  end

  def initialize
    self.class.reset
  end

  def sendmail(mail, from, to)
    @@deliveries << [mail, from, to]
    'OK'
  end

  def rset
    Net::SMTP::Response.parse('250 OK')
  end

  def start(*args)
    @started = true

    if block_given?
      result = yield(self)
      @started = false

      return result
    else
      return self
    end
  end

  def started?
    @started
  end

  def finish
    @started = false
    return true
  end

  def enable_tls(context)
    raise ArgumentError, "SMTPS and STARTTLS is exclusive" if @@starttls == :always
    @@tls = true
    context
  end

  def disable_tls
    @@tls = false
  end

  def enable_starttls(context = nil)
    raise ArgumentError, "SMTPS and STARTTLS is exclusive" if @@tls
    @@starttls = :always
    context
  end

  def enable_starttls_auto(context)
    raise ArgumentError, "SMTPS and STARTTLS is exclusive" if @@tls
    @@starttls = :auto
    context
  end

  def disable_starttls
    @@starttls = false
  end
end
