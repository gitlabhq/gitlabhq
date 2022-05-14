# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CollectedDataCategoriesMetric < GenericMetric
          value do
            ::ServicePing::PermitDataCategories.new.execute.to_a
          end
        end
      end
    end
  end
end
