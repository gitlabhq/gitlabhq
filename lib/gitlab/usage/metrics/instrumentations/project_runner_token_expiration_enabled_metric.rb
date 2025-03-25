# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ProjectRunnerTokenExpirationEnabledMetric < GenericMetric
          def value
            return true if Gitlab::CurrentSettings.project_runner_token_expiration_interval&.positive?

            NamespaceSetting.where(NamespaceSetting.arel_table[:project_runner_token_expiration_interval].gt(0)).exists?
          end
        end
      end
    end
  end
end
