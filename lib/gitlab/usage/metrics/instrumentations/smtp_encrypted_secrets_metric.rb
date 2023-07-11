# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class SmtpEncryptedSecretsMetric < GenericMetric
          value do
            Gitlab::Email::SmtpConfig.encrypted_secrets.active?
          end
        end
      end
    end
  end
end
