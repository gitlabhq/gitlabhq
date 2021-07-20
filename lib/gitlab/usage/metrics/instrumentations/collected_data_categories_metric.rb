# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CollectedDataCategoriesMetric < GenericMetric
          def value
            ::ServicePing::PermitDataCategoriesService.new.execute
          end
        end
      end
    end
  end
end
