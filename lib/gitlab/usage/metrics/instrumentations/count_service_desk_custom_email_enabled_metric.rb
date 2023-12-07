# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountServiceDeskCustomEmailEnabledMetric < DatabaseMetric
          operation :count

          relation do
            ServiceDeskSetting.where(custom_email_enabled: true)
          end
        end
      end
    end
  end
end
