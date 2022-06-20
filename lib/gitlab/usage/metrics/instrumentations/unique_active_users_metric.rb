# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class UniqueActiveUsersMetric < DatabaseMetric
          operation :count
          relation { ::User.active }

          metric_options do
            {
              batch_size: 10_000
            }
          end

          def time_constraints
            case time_frame
            when '28d'
              monthly_time_range_db_params(column: :last_activity_on)
            else
              super
            end
          end
        end
      end
    end
  end
end
