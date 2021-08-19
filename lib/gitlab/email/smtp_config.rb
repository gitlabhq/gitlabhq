# frozen_string_literal: true

module Gitlab
  module Email
    class SmtpConfig
      def self.encrypted_secrets
        Settings.encrypted(Gitlab.config.gitlab.email_smtp_secret_file)
      end

      def self.secrets
        self.new
      end

      def initialize
        @secrets ||= self.class.encrypted_secrets.config
      rescue StandardError => e
        Gitlab::AppLogger.error "SMTP encrypted secrets are invalid: #{e.inspect}"
      end

      def username
        @secrets&.fetch(:user_name, nil)&.chomp
      end

      def password
        @secrets&.fetch(:password, nil)&.chomp
      end
    end
  end
end
