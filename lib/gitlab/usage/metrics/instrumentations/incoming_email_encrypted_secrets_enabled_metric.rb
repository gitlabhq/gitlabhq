# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class IncomingEmailEncryptedSecretsEnabledMetric < GenericMetric
          value do
            Gitlab::Email::IncomingEmail.encrypted_secrets.active?
          end
        end
      end
    end
  end
end
