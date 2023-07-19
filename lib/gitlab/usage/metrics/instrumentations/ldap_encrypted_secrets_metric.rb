# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class LdapEncryptedSecretsMetric < GenericMetric
          value do
            Gitlab::Auth::Ldap::Config.encrypted_secrets.active?
          end
        end
      end
    end
  end
end
