# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUsersUsingApproveQuickActionMetric < RedisHLLMetric
          event_names :i_quickactions_approve
        end
      end
    end
  end
end
