# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class VersionMetric < GenericMetric
          value do
            Gitlab::VERSION
          end
        end
      end
    end
  end
end
