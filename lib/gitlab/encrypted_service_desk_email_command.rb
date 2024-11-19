# frozen_string_literal: true

module Gitlab
  class EncryptedServiceDeskEmailCommand < EncryptedCommandBase
    DISPLAY_NAME = "SERVICE_DESK_EMAIL"
    EDIT_COMMAND_NAME = "gitlab:service_desk_email:secret:edit"

    class << self
      def encrypted_secrets
        Gitlab::Email::ServiceDeskEmail.encrypted_secrets
      end

      def encrypted_file_template
        <<~YAML
          # password: '123'
          # user: 'gitlab-incoming@gmail.com'
        YAML
      end
    end
  end
end
