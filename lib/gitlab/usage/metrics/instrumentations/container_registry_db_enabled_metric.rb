# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ContainerRegistryDbEnabledMetric < GenericMetric
          value do
            Gitlab::CurrentSettings.container_registry_db_enabled
          end
        end
      end
    end
  end
end
