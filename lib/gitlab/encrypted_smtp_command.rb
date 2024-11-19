# frozen_string_literal: true

module Gitlab
  class EncryptedSmtpCommand < EncryptedCommandBase
    DISPLAY_NAME = "SMTP"
    EDIT_COMMAND_NAME = "gitlab:smtp:secret:edit"

    class << self
      def encrypted_secrets
        Gitlab::Email::SmtpConfig.encrypted_secrets
      end

      def encrypted_file_template
        <<~YAML
          # password: '123'
          # user_name: 'gitlab-inst'
        YAML
      end
    end
  end
end
