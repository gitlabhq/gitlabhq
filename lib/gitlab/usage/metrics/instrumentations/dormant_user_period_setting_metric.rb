# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class DormantUserPeriodSettingMetric < GenericMetric
          value do
            ::Gitlab::CurrentSettings.deactivate_dormant_users_period
          end
        end
      end
    end
  end
end
