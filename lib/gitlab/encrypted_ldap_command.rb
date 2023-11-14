# frozen_string_literal: true

module Gitlab
  class EncryptedLdapCommand < EncryptedCommandBase
    DISPLAY_NAME = "LDAP"
    EDIT_COMMAND_NAME = "gitlab:ldap:secret:edit"

    class << self
      def encrypted_secrets
        Gitlab::Auth::Ldap::Config.encrypted_secrets
      end

      def encrypted_file_template
        <<~YAML
          # main:
          #   password: '123'
          #   bind_dn: 'gitlab-adm'
        YAML
      end
    end
  end
end
