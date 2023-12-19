# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ReplyByEmailEnabledMetric < GenericMetric
          value do
            Gitlab::Email::IncomingEmail.enabled?
          end
        end
      end
    end
  end
end
