# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountTopLevelGroupsRequiringTwoFactorAuthenticationMetric < DatabaseMetric
          operation :count

          relation do
            Group.top_level.requiring_two_factor_authentication(true)
          end
        end
      end
    end
  end
end
