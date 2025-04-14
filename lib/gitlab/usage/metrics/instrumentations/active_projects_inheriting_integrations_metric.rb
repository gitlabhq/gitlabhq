# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ActiveProjectsInheritingIntegrationsMetric < BaseIntegrationsMetric
          operation :count

          relation do |options|
            Integration.active
              .where.not(project: nil)
              .where.not(inherit_from_id: nil)
              .where(type: integrations_name(options))
          end
        end
      end
    end
  end
end
