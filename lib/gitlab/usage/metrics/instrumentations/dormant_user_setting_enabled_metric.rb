# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class DormantUserSettingEnabledMetric < GenericMetric
          value do
            ::Gitlab::CurrentSettings.deactivate_dormant_users
          end
        end
      end
    end
  end
end
