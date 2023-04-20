# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ServiceDeskEmailEncryptedSecretsEnabledMetric < GenericMetric
          value do
            Gitlab::Email::ServiceDeskEmail.encrypted_secrets.active?
          end
        end
      end
    end
  end
end
