# frozen_string_literal: true

require 'mail/network/delivery_methods/smtp'

# Monkey patch mail 2.8.1 to make it possible to disable STARTTLS.
# without having to change existing settings.
# This brings in changes from https://github.com/mikel/mail/pull/1536,
# which has not been released yet.
module Mail
  class SMTP
    def initialize(values)
      self.settings = DEFAULTS.dup
      settings[:enable_starttls_auto] = nil
      settings.merge!(values)
    end

    private

    # `key` is said to be provided when `settings` has a non-nil value for `key`.
    def setting_provided?(key)
      !settings[key].nil?
    end

    # Yields one of `:always`, `:auto` or `false` based on `enable_starttls` and `enable_starttls_auto` flags.
    # Yields `false` when `smtp_tls?`.
    def smtp_starttls
      return false if smtp_tls?

      if setting_provided?(:enable_starttls) && settings[:enable_starttls]
        # enable_starttls: provided and truthy
        case settings[:enable_starttls]
        when :auto then :auto
        when :always then :always
        else
          :always
        end
      elsif setting_provided?(:enable_starttls_auto)
        # enable_starttls: not provided or false
        settings[:enable_starttls_auto] ? :auto : false
      else
        # enable_starttls_auto: not provided
        # enable_starttls: when provided then false
        # use :auto when neither enable_starttls* provided
        setting_provided?(:enable_starttls) ? false : :auto
      end
    end

    def smtp_tls?
      (setting_provided?(:tls) && settings[:tls]) || (setting_provided?(:ssl) && settings[:ssl])
    end

    def start_smtp_session(&block)
      build_smtp_session.start(settings[:domain], settings[:user_name], settings[:password],
        settings[:authentication], &block)
    end

    def build_smtp_session
      if smtp_tls? && (settings[:enable_starttls] || settings[:enable_starttls_auto])
        # rubocop:disable Layout/LineLength
        raise ArgumentError,
          ":enable_starttls and :tls are mutually exclusive. Set :tls if you're on an SMTPS connection. Set :enable_starttls if you're on an SMTP connection and using STARTTLS for secure TLS upgrade."
        # rubocop:enable Layout/LineLength
      end

      Net::SMTP.new(settings[:address], settings[:port]).tap do |smtp|
        if smtp_tls?
          smtp.disable_starttls
          smtp.enable_tls(ssl_context)
        else
          smtp.disable_tls

          case smtp_starttls
          when :always
            smtp.enable_starttls(ssl_context)
          when :auto
            smtp.enable_starttls_auto(ssl_context)
          else
            smtp.disable_starttls
          end
        end

        smtp.open_timeout = settings[:open_timeout] if settings[:open_timeout]
        smtp.read_timeout = settings[:read_timeout] if settings[:read_timeout]
      end
    end
  end
end
