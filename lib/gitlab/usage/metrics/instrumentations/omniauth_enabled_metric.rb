# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class OmniauthEnabledMetric < GenericMetric
          value do
            Gitlab::Auth.omniauth_enabled?
          end
        end
      end
    end
  end
end
