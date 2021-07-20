# frozen_string_literal: true

# For large tables, PostgreSQL can take a long time to count rows due to MVCC.
# Implements a distinct and ordinary batch counter
# Needs indexes on the column below to calculate max, min and range queries
# For larger tables just set use higher batch_size with index optimization
#
# In order to not use a possible complex time consuming query when calculating min and max for batch_distinct_count
# the start and finish can be sent specifically
#
# Grouped relations can be used as well. However, the preferred batch count should be around 10K because group by count is more expensive.
#
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22705
#
# Examples:
#  extend ::Gitlab::Database::BatchCount
#  batch_count(User.active)
#  batch_count(::Clusters::Cluster.aws_installed.enabled, :cluster_id)
#  batch_count(Namespace.group(:type))
#  batch_distinct_count(::Project, :creator_id)
#  batch_distinct_count(::Project.aimed_for_deletion.service_desk_enabled.where(time_period), start: ::User.minimum(:id), finish: ::User.maximum(:id))
#  batch_distinct_count(Project.group(:visibility_level), :creator_id)
#  batch_sum(User, :sign_in_count)
#  batch_sum(Issue.group(:state_id), :weight))
module Gitlab
  module Database
    module BatchCount
      def batch_count(relation, column = nil, batch_size: nil, start: nil, finish: nil)
        BatchCounter.new(relation, column: column).count(batch_size: batch_size, start: start, finish: finish)
      end

      def batch_distinct_count(relation, column = nil, batch_size: nil, start: nil, finish: nil)
        BatchCounter.new(relation, column: column).count(mode: :distinct, batch_size: batch_size, start: start, finish: finish)
      end

      def batch_sum(relation, column, batch_size: nil, start: nil, finish: nil)
        BatchCounter.new(relation, column: nil, operation: :sum, operation_args: [column]).count(batch_size: batch_size, start: start, finish: finish)
      end

      class << self
        include BatchCount
      end
    end
  end
end
