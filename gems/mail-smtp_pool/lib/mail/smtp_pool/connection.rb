# frozen_string_literal: true

# A connection object that can be used to deliver mail.
#
# This is meant to be used in a pool so the main difference between this
# and Mail::SMTP is that this expects deliver! to be called multiple times.
#
# SMTP connection reset and error handling is handled by this class and
# the SMTP connection is not closed after a delivery.

require 'mail'

module Mail
  class SMTPPool
    class Connection < Mail::SMTP
      def initialize(values)
        super

        @smtp_session = nil
      end

      def deliver!(mail)
        response = Mail::SMTPConnection.new(connection: smtp_session, return_response: true).deliver!(mail)

        settings[:return_response] ? response : self
      end

      def finish
        finish_smtp_session if @smtp_session && @smtp_session.started?
      end

      private

      def smtp_session
        return start_smtp_session if @smtp_session.nil? || !@smtp_session.started?
        return @smtp_session if reset_smtp_session

        finish_smtp_session
        start_smtp_session
      end

      def start_smtp_session
        @smtp_session = build_smtp_session.start(settings[:domain], settings[:user_name], settings[:password], settings[:authentication])
      end

      def reset_smtp_session
        !@smtp_session.instance_variable_get(:@error_occurred) && @smtp_session.rset.success?
      rescue Net::SMTPError, IOError
        false
      end

      def finish_smtp_session
        @smtp_session.finish
      rescue Net::SMTPError, IOError
      ensure
        @smtp_session = nil
      end
    end
  end
end
