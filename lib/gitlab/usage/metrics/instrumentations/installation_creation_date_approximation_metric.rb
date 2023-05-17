# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class InstallationCreationDateApproximationMetric < GenericMetric
          value do
            [User.first, ApplicationSetting.first].compact.pluck(:created_at).compact.min
          end
        end
      end
    end
  end
end
