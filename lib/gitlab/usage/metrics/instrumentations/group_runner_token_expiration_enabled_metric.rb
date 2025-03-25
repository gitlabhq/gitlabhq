# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GroupRunnerTokenExpirationEnabledMetric < GenericMetric
          def value
            return true if Gitlab::CurrentSettings.group_runner_token_expiration_interval&.positive?

            expiration_interval = NamespaceSetting.arel_table[:subgroup_runner_token_expiration_interval]
            NamespaceSetting.where(expiration_interval.gt(0)).exists?
          end
        end
      end
    end
  end
end
