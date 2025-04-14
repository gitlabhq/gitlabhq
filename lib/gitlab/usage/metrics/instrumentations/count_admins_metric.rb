# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountAdminsMetric < DatabaseMetric
          operation :count

          timestamp_column :created_at

          relation do
            User.admins
          end
        end
      end
    end
  end
end
