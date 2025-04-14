# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ActiveInstanceIntegrationsMetric < BaseIntegrationsMetric
          operation :count

          relation do |options|
            Integration.active.where(instance: true, type: integrations_name(options))
          end
        end
      end
    end
  end
end
