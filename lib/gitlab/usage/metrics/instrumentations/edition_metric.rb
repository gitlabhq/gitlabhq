# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class EditionMetric < GenericMetric
          value do
            if Gitlab.ee?
              ::License.current&.edition || 'EE Free'
            else
              'CE'
            end
          end
        end
      end
    end
  end
end
